;;;; package.lisp

(defpackage #:cl-bloom
  (:use #:cl #:cl-murmurhash)
  (:nicknames :bloom)
  (:export
   :*false-drop-rate*
   :bloom-filter-p
   :make-filter
   :destroy-filter
   :with-filter
   :make-set-filter
   :add
   :memberp
   :copy-filter
   :make-compatible-filter
   :filter-union
   :filter-nunion
   :filter-ior
   :filter-intersection
   :filter-nintersection
   :filter-and))
