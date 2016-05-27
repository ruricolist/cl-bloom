;;;; cl-bloom.asd

(asdf:defsystem #:cl-bloom
  :author "Paul M. Rodriguez <pmr@ruricolist.com>"
  :description "Simple Bloom filters with efficient hashing."
  :license "MIT"
  :serial t
  :depends-on (#:cl-murmurhash
               #:static-vectors)
  :components ((:file "package")
               (:file "cl-bloom")))
