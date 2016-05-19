;;;; cl-bloom.lisp

(in-package #:cl-bloom)

;;; "cl-bloom" goes here. Hacks and glory await!

(defparameter *false-drop-rate* 1/1000
  "Acceptable rate of false drops.")

(defun opt-degree ()
  (ceiling (log *false-drop-rate* 1/2)))

(defun opt-order (capacity)
  (ceiling (* (log (/ 1 *false-drop-rate*))
              #.(/ (expt (log 2) 2))
              capacity)))

(defun make-bit-vector (size &key (allocation :heap))
  (assert (member allocation '(nil :heap :static)) nil
    (error "The `allocation` should be either :heap or :static, or it's set to :heap by default."))
  (let ((params `(,size :element-type bit :initial-element 0)))
    (apply (case allocation
             ((nil :heap) 'make-array)
             (:static 'static-vectors:make-static-vector))
           params)))

(defclass bloom-filter ()
  ((array :accessor filter-array :initarg :array :type simple-bit-vector)
   (array-static-p :accessor filter-array-static-p :initarg :array-static-p :type symbol)
   (order :accessor filter-order :initarg :order :type integer)
   (degree :accessor filter-degree :initarg :degree :type integer)
   (seed :accessor filter-seed :initarg :seed :type integer
         :documentation "Cache the value of MURMURHASH:*DEFAULT-SEED*
         at the time the filter was created, lest changing the default
         seed invalidate the filter."))
  (:default-initargs
   :degree (opt-degree)
   :order 256
   :seed *default-seed*))

(defmethod initialize-instance :after ((filter bloom-filter) &key order static)
  (setf (slot-value filter 'array)
        (make-bit-vector order :allocation (if static :static :heap))
        (slot-value filter 'array-static-p) static))

(defun bloom-filter-p (object)
  (typep object 'bloom-filter))

(defun make-filter (&key (capacity 256) (false-drop-rate *false-drop-rate*) (static nil))
  "Return a Bloom filter long enough to hold CAPACITY entries with the
specified FALSE-DROP-RATE."
  (assert (< 0 false-drop-rate 1))
  (assert (> capacity 0))
  (let* ((*false-drop-rate* false-drop-rate)
         (order (opt-order capacity)))
    (make-instance 'bloom-filter :order order :static static)))

(defun make-set-filter (list &key (static nil))
  "Make a Bloom filter from the elements of LIST, optimizing the order and
degree of the filter according to the size of the set."
  (declare (list list))
  (let* ((*default-seed* (make-perfect-seed list))
         (filter (make-filter :capacity (length list) :static static)))
    (dolist (element list)
      (add filter element))
    filter))

;; Cf. Kirsch and Mitzenmacher, "Less Hashing, Same
;; Performance: Building a Better Bloom Filter".
;; <http://www.eecs.harvard.edu/~kirsch/pubs/bbbf/esa06.pdf>

(declaim (inline fake-hash))

(defun fake-hash (hash1 hash2 index order)
  (mod (+ hash1 (* index hash2)) order))

(defun add (filter element)
  "Make FILTER include ELEMENT."
  (declare (bloom-filter filter))
  (with-slots (order degree array seed) filter
    (let* ((hash1 (murmurhash element :seed seed))
           (hash2 (murmurhash element :seed hash1)))
      (loop for i to (1- degree)
            for index = (fake-hash hash1 hash2 i order)
            do (setf (sbit array index) 1)))))

(defun memberp (filter element)
  "Return NIL if ELEMENT is definitely not present in FILTER.
Return T if it might be present."
  (declare (bloom-filter filter))
  (with-slots (order degree array seed) filter
    (let* ((hash1 (murmurhash element :seed seed))
           (hash2 (murmurhash element :seed hash1)))
      (loop for i to (1- degree)
            for index = (fake-hash hash1 hash2 i order)
            always (= 1 (sbit array index))))))

(defun make-compatible-filter (filter)
  "Return a new Bloom filter having the same order, degree, and seed
as FILTER."
  (declare (bloom-filter filter))
  (with-slots (order degree seed) filter
    (make-instance 'bloom-filter
                   :order order
                   :degree degree
                   :seed seed)))

(define-condition incompatible-filter (error)
  ((filter :initarg :filter :reader filter)))

(defun compatible? (filter1 filter2)
  (declare (bloom-filter filter1 filter2))
  (and (= (filter-order filter1)
          (filter-order filter2))
       (= (filter-degree filter1)
          (filter-degree filter2))
       (= (filter-seed filter1)
          (filter-seed filter2))))

(defun filter-nunion (filter1 filter2)
  "Return the union of FILTER1 and FILTER2, overwriting FILTER1."
  (declare (bloom-filter filter1 filter2))
  (unless (compatible? filter1 filter2)
    (error 'incompatible-filter :filter filter2))
  (bit-ior (filter-array filter1) (filter-array filter2)
           (filter-array filter1))
  filter1)

(defun copy-filter (filter)
  "Return a new Bloom filter like FILTER."
  (declare (bloom-filter filter))
  (filter-nunion
   (make-compatible-filter filter)
   filter))

(defun destroy-filter (filter)
  "Destroy a Bloom filter instance. When its bit array is allocated statically,
then free the memory and set the reference of each slot to nil;
otherwise, set all the references of slots to nil."
  (with-slots (array array-static-p order degree seed) filter
    (setf order nil degree nil seed nil)
    (if array-static-p
        (static-vectors:free-static-vector array)
        (setf array nil))
    (setf array nil array-static-p nil))
  filter)

(defun filter-union (filter1 filter2)
  "Return the union of FILTER1 and FILTER2 as a new filter."
  (declare (bloom-filter filter1 filter2))
  (unless (compatible? filter1 filter2)
    (error 'incompatible-filter :filter filter2))
  (let ((filter3 (make-compatible-filter filter1)))
   (bit-ior (filter-array filter1) (filter-array filter2)
            (filter-array filter3))
   filter3))

(defun filter-ior (&rest filters)
  "Return union of all FILTERS as a new filter."
  (reduce #'filter-nunion
          (cdr filters)
          :initial-value (copy-filter (car filters))))

(defun filter-nintersection (filter1 filter2)
  "Return the intersection of FILTER1 and FILTER2, overwriting FILTER1."
  (declare (bloom-filter filter1 filter2))
  (unless (compatible? filter1 filter2)
    (error 'incompatible-filter :filter filter2))
  (bit-and (filter-array filter1) (filter-array filter2)
           (filter-array filter1))
  filter1)

(defun filter-and (&rest filters)
  "Return intersection of all FILTERS as a new filter."
  (reduce #'filter-nintersection
          (cdr filters)
          :initial-value (copy-filter (car filters))))

(defun filter-intersection (filter1 filter2)
  "Return the intersection of FILTER1 and FILTER2 as a new filter."
  (declare (bloom-filter filter1 filter2))
  (unless (compatible? filter1 filter2)
    (error 'incompatible-filter :filter filter2))
  (let ((filter3 (make-compatible-filter filter1)))
    (bit-and (filter-array filter1) (filter-array filter2)
             (filter-array filter3))
    filter3))
