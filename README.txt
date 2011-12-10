A simple Common Lisp implementation of Bloom filters with efficient
hashing.

To make an empty filter, use MAKE-FILTER, which takes parameters for
capacity and false drop (false positive) rate. If no false drop rate
is specified, the value of *FALSE-DROP-RATE* is used.

     (defparameter *my-filter*
      (bloom:make-filter :capacity 1000 :false-drop-rate 1/1000))

Good values for the "order" (size) and "degree" (number of hashes) are
calculated internally to obtain the theoretically ideal dimensions for
a Bloom filter having the given parameters.

To add an element to a filter, use ADD:

     (bloom:add *my-filter* "Add me")

To test for membership, use MEMBERP:

     (bloom:memberp *my-filter* "Add me")
     => T

When filters are used as sets, FILTER-UNION, FILTER-NUNION,
FILTER-NINTERSECTION, and FILTER-INTERSECTION behave like their
namesakes. FILTER-IOR and FILTER-AND are shorthands for lists of
filters.

The other utilities for composing filters are MAKE-COMPATIBLE-FILTER,
which takes a filter and returns an empty, compatible filter, and
COPY-FILTER, which takes a filter and returns an independent copy.

The utility MAKE-SET-FILTER covers one use case for Bloom filters:
given a list, it returns a filter suitable for testing membership in
that list, considered as a set.
