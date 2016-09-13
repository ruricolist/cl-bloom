;;;; cl-bloom.asd

#+(or sbcl ccl cmucl ecl lispworks allegro)
(eval-when (:compile-toplevel :load-toplevel :execute)
  (pushnew :cl-bloom-sv *features*))

(asdf:defsystem #:cl-bloom
  :author "Paul M. Rodriguez <pmr@ruricolist.com>"
  :description "Simple Bloom filters with efficient hashing."
  :license "MIT"
  :serial t
  :depends-on (#:cl-murmurhash
               #+cl-bloom-sv
               #:static-vectors)
  :components ((:file "package")
               (:file "cl-bloom")))
