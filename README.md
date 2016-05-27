A simple Common Lisp implementation of Bloom filters with efficient hashing.

To make an empty filter, use MAKE-FILTER, which takes parameters for capacity and false drop (false positive) rate. If no false drop rate
is specified, the value of *FALSE-DROP-RATE* is used. And also the third parameter specify whether the space is allocated from heap or by using `static-vectors:make-static-vector`.

```common-lisp
;;; the space is allocated from heap by default
(defparameter *my-filter*
  (bloom:make-filter :capacity 1000 :false-drop-rate 1/1000))
;;; by setting the third parameter `:static` to T, 
;;; the space will be allocated statically
(defparameter *my-filter*
  (bloom:make-filter :capacity 1000 :false-drop-rate 1/1000 :static t))
```

Good values for the "order" (size) and "degree" (number of hashes) are
calculated internally to obtain the theoretically ideal dimensions for
a Bloom filter having the given parameters.

To add an element to a filter, use **ADD**:

```common-lisp
(bloom:add *my-filter* "Add me")
```

To test for membership, use **MEMBERP**:

```common-lisp
(bloom:memberp *my-filter* "Add me")
=> T
```

Since when the space is allocated by using `static-vectors:make-static-vector`, users must explicitly free the space by using `static-vectors:free-static-vector`. We thus provide two APIs, `destroy-filter` and `with-filter`, to help with that:

### destroy-filter
```common-lisp
(bloom:destroy-filter *filter*) 
;; => a destroyed filter instance, where all slots are being either set to NIL or freed
```

### with-filter
```common-lisp
;;; A 'with-' wrapper around filter, pretty useful when the space is allocated statically;
;;; it will free the space 'automatically'.
CL-USER> (bloom:with-filter (filter :capacity 10 :static t)
           (bloom:add filter "add")
           (bloom:add filter "minus")
           (print (bloom:memberp filter "add"))
           (print (bloom:memberp filter "minus")))

T 
T 
T
```

When filters are used as sets, FILTER-UNION, FILTER-NUNION, FILTER-NINTERSECTION, and FILTER-INTERSECTION behave like their namesakes. FILTER-IOR and FILTER-AND are shorthands for lists of filters.

The other utilities for composing filters are MAKE-COMPATIBLE-FILTER, which takes a filter and returns an empty, compatible filter, and COPY-FILTER, which takes a filter and returns an independent copy.

The utility MAKE-SET-FILTER covers one use case for Bloom filters: given a list, it returns a filter suitable for testing membership in
that list, considered as a set.
