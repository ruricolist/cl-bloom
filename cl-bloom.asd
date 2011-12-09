;;;; cl-bloom.asd

(asdf:defsystem #:cl-bloom
  :serial t
  :depends-on (#:cl-murmurhash)
  :components ((:file "package")
               (:file "cl-bloom")))

