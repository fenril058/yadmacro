;;; yadmacro-test.el --- test for yadmacro.el           -*- lexical-binding: t; -*-

;; Copyright (C) 2024  ril

;; Author: ril <fenril.nh@gmail.com>
;; Keywords: convenience

;;; Commentary:

;; emacs -Q -l yadmacro.el --batch --eval '(load-file "yadmacro-test.el")'

;;; Code:
(require 'ert)
(require 'yadmacro)

(ert-deftest yadmacro-list-shift-1 ()
  (should (equal '((1 2) (3 4 5 6))
                 (yadmacro-list-shift
                  '(1 2 3) '(4 5 6)))))

(ert-deftest yadmacro-prefix-matched-sublist-1 ()
  (should (equal '(2 1 0 "A")
                 (yadmacro-prefix-matched-sublist
                  '(2 1 0 "A" 5 4 3) '(2 1 0 "A" "H" "O")))))

(ert-deftest yadmacro-detect-repetitive-pattern-0 ()
  "The original expectation from the comments is
(((\"a\" \"b\" \"a\" \"b\" \"c\" \"c\") (\"a\" \"b\" \"a\" \"b\" \"c\" \"c\")) 0)
but fails."
  (should (equal '((("a" "b" "a" "b" "c" "c")
                    ("a" "b" "a" "b" "c" "c")
                    ("d" "e" "f" "g")) 0)
                 ;;
                 (cl-multiple-value-list
                  (yadmacro-detect-repetitive-pattern
                   '("a" "b" "a" "b" "c" "c"
                     "a" "b" "a" "b" "c" "c" "d" "e" "f" "g"))))))

(ert-deftest yadmacro-detect-repetitive-pattern-1 ()
  "The original expectation from the comments is
(((\"a\" \"b\") (\"a\" \"b\")) 0)
but fails."
  (should (equal '((("a" "b") ("a" "b") ("c" "-")) 0)
                 (yadmacro-detect-repetitive-pattern
                  '("a" "b" "a" "b" "c" "-"
                    "a" "b" "a" "b" "c" "c" "d" "e" "f" "g")))))

(ert-deftest yadmacro-detect-repetitive-pattern-2 ()
  (should (equal '((("a" "b") ("a" "b")) 0)
                 (yadmacro-detect-repetitive-pattern
                  '("a" "b"
                    "a" "b")))))

(ert-deftest yadmacro-detect-repetitive-pattern-3 ()
  (should (equal '((("a" "b") ("a" "b") ("a" "b")) 0)
                 (yadmacro-detect-repetitive-pattern
                  '("a" "b"
                    "a" "b" "a" "b")))))

(ert-deftest yadmacro-detect-repetitive-pattern-4 ()
  (should (equal '((("a" "b" "a" "b") ("a" "b" "a" "b")) 0)
                 (yadmacro-detect-repetitive-pattern
                  '("a" "b" "a" "b"
                    "a" "b" "a" "b")))))

(ert-deftest yadmacro-detect-repetitive-pattern-5 ()
  (should (equal '(((49 48 49 44) (49 48 50 44) (49 48 51 44)) 0)
                 (yadmacro-detect-repetitive-pattern
                  '(49 48 49 44
                       49 48 50 44
                       49 48 51 44)))))

(ert-deftest yadmacro-detect-repetitive-pattern-6 ()
  (should (equal '(((5 4 3 2 1 0 "A") (5 4 3 2 1 0 "A")) 4)
                 (yadmacro-detect-repetitive-pattern
                  '(2 1 0 "A" 5 4 3 2 1 0 "A" "H" "O")))))

(ert-deftest yadmacro-predict-repeat-1 ()
  (should (equal '(((5 4 3 2 1 0 "A") (5 4 3 2 1 0 "A")) 4)
                 (yadmacro-predict-repeat
                  '(2 1 0 "A" 5 4 3 2 1 0 "A" "H" "O")))))

(ert-deftest yadmacro-split-seq-if-1 ()
  (should (equal '((49 51) (49 52))
                 (yadmacro-split-seq-if
                  'identity '(49 51 nil 49 52 nil)))))

(ert-deftest yadmacro-split-seq-if-2 ()
  (should (equal '((49 51) (49 52))
                 (yadmacro-split-seq-if
                  'identity '(nil 49 51 nil 49 52 nil)))))

(ert-deftest yadmacro-split-seq-if-3 ()
  (should (equal '((49 51) (49 52))
                 (yadmacro-split-seq-if
                  'identity '(nil 49 51 nil 49 52)))))

(ert-deftest yadmacro-position-subseq-1 ()
  (should (= 1
             (yadmacro-position-subseq
              '(nil 49 51 nil 49 52) '(49 51)))))

(ert-deftest yadmacro-position-subseq-2 ()
  (should (= 4
             (yadmacro-position-subseq
              '(nil 49 51 nil 49 52) '(49 52)))))

(ert-deftest yadmacro-get-numbers-and-position-1 ()
  "1の位置から3桁分105, 5の位置から2桁分13がある。"
  (should (equal '((1 3 103) (5 2 13))
                 (yadmacro-get-numbers-and-position
                  '(nil 49 48 51 nil 49 51 nil nil)))))

(ert-deftest yadmacro-get-incremented-sequence-1 ()
  "The original expectations from the comments is
'(49 48 53 44 49 55 65 return) ; \"105,17A\"
but fails"
  (should (equal '(49 48 52 44 49 53 65 return)   ; "104,15A"?
                 (yadmacro-get-incremented-sequence
                  '((return 65 53 49 44 52 48 49) ; "104,15A"
                    (return 65 51 49 44 51 48 49) ; "103,13A"
                    (return 65 49 49 44 50 48 49) ; "102,11A"
                    )))))

(ert-run-tests-batch-and-exit)

(provide 'yadmacro-test)
;;; yadmacro-test.el ends here
