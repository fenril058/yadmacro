;;; yadmacro.el --- yet another dmacro -*- lexical-binding: t; -*-

;; Copyright (C) 2024 ril

;; Author: ril <fenril.nh@gmail.com>
;; Version: 0.1.0
;; Keywords: convenience
;; URL: https://github.com/fenril058/yadmacro
;; Package-Requires: ((emacs "24.3"))

;; SPDX-License-Identifier: MIT

;;; Commentary:

;; This package offer `yadmacro' command, which detects repetitive key
;; operations and repeats them.  If the operations include number
;; incrementation or decrementation, continue it.
;;
;; You have to bind `yadmacro' command to some key and use it via the
;; key, because `last-command-event' is used to deliminate the
;; repetitive operations.
;;
;; Usage:
;;   (require 'yadmacro)
;;   (global-yadmacro-mode 1)
;;
;; The default repeat key is "<f9>".
;; You can customize the key to change `yadmacro-key'.
;;
;; For example, With use-package.el:
;;   (use-package yadmacro
;;     :custom (yadmacro-key "C-t")
;;     :config (global-yadmacro-mode 1)
;;
;; Or, with leaf.el:
;;   (leaf yadmacro
;;     :custom (yadmacro-key . "C-t")
;;     :global-minor-mode t)
;;
;; If you wnat to disable `yadmaacro-mode' in some major modes,
;; you can add the major mode to the list `yadmacro-disable-modes'.
;;
;; You can directory bind `yadmacor' like that:
;;   (use-package yadmacro
;;     :bind ("C-t" . yadmacro")
;;
;; Of course you do not need to enable `dmacro-mode' in that case.
;;


;;; Code:

(require 'cl-lib)

(defgroup yadmacro nil "New Dynamic Macro"
  :group 'convenient
  :prefix "yadmacro-")

(defcustom yadmacro-key "<f9>"
  "Repeat key."
  :type 'string
  :group 'yadmacro)

(defcustom yadmacro-mode-lighter ""
  "lighter of yadmacro-mode"
  :type 'string
  :group 'yadmacro)

(defcustom yadmacro-printf-debug nil
  "Enable dubug mode"
  :type 'boolean
  :group 'yadmacro)

(defcustom yadmacro-use-disable-list t
  "To select wheter enable list or disalbe list.
If nil, global-yadmacro-mode enables yadmacro-mode in the modes
which are the member of `yadmacro-enable-modes'. If non-nil,
global-yadmacro-mode enables yadmacro-mode in all modes except in
`yadmacro-disable-modes'."
  :type 'boolean
  :group 'yadmacro)

(defcustom yadmacro-enable-modes '(text-mode org-mode)
  "Major modes which `yadmacro-mode' can run on."
 :type 'list
 :group 'yadmacro)

(defcustom yadmacro-disable-modes nil
  "Major modes which `yadmacro-mode' can not run on."
  :type 'list
  :group 'yadmacro)

(defvar yadmacro-mode-map (make-sparse-keymap)
  "keymap for `ydamcro-mode'.")

(defvar yadmacro-repeat-count 0)

(defun yadmacro-devide-list (source n)
  "Divide SOURCE list into sublists of length N.
If N is zero, it raises an error indicating \"zero length\"."
  (if (zerop n) (error "zero length"))
  (cl-labels ((rec (source acc)
                (let ((rest (nthcdr n source)))
                  (if (consp rest)
                      (rec rest (cons
                                 (cl-subseq source 0 n)
                                 acc))
                    (nreverse
                     (cons source acc))))))
    (if source (rec source nil) nil)))

(defun yadmacro-list-shift (lst1 lst2)
  "Shift the last elements of the LST1 to the beginning of the LST2."
  (list (reverse (cdr (reverse lst1)))
        (cons (car (reverse lst1)) lst2)))

(defun yadmacro-is-number (x)
  "If X is a number in ASCII return X otherwise return nil"
  (if (and (numberp x)
           (<= 48 x)
           (<= x 57))
      x nil))

(defun yadmacro-is-not-number (x)
  "If X is not a number in ASCII return nil otherwise return X"
  (if (and (numberp x)
           (<= 48 x)
           (<= x 57))
      nil x))

(defun yadmacro-prefix-matched-sublist (lst1 lst2)
  "Return a sublist of LST1 up to the point where it differs from LST2."
  (let ((idx 0))
    (while (equal (nth idx lst1)
                  (nth idx lst2))
      (cl-incf idx))
    (cl-subseq lst1 0 idx)))

(defun yadmacro-detect-repetitive-pattern (lst)
  "Searche for repetitive patterns within the input list LST.

This function divides the list into two halves and compares them
iteratively until a repetitive pattern is found or the end of the
list is reached. During this search, numbers in ASCII regarded as
the same.

If a repetitive pattern is detected, it returns a list consisting
of the repeated sequence and the position in the input list where
the repetition ends. If no repetitive pattern is found, it
predicts and executes the next action based on the input sequence
by calling `yadmacro-predict-repeat' with LST."
  (let* ((center-pos (floor (length lst) 2))
         ;; 数字[0-9]同士は同じものとみなす。
         ;; あとから差を出して連番生成できるようにするため。
         (lst1 (mapcar
                'yadmacro-is-not-number (cl-subseq lst 0 center-pos)))
         (lst2 (mapcar
                'yadmacro-is-not-number (cl-subseq lst center-pos)))
         shifted)
    (while (and lst1
                (not (equal lst1
                            (cl-subseq lst2 0 (length lst1)))))
      (setq shifted (yadmacro-list-shift lst1 lst2)
            lst1   (car  shifted)
            lst2   (cadr shifted)))
    ;; ループが終わったら,
    ;; 数字を除いたとき完全一致の繰り返しがあるとき
    ;; lst1はlst2の先頭一致リストになり、
    ;; 数字を除いても完全一致の繰り返しがないとき
    ;; lst1はnilになる
    (cond
     (lst1
      (let ((begin 0)
            (end   (length lst1)))
        (while (equal lst1
                      (cl-subseq lst2 begin (min (length lst2)
                                                 end)))
          (setq begin (+ begin (length lst1))
                end   (+ end   (length lst1))))
        ;; 繰り返しの全体と、途中までの場合何桁目まで入力しているか？を返す
        (cl-values (yadmacro-devide-list (cl-subseq lst 0 (min (length lst)
                                                               (+ end (length lst1))))
                                         (length lst1))
                   0)))
     (t
      (yadmacro-predict-repeat lst)))))

(defun yadmacro-predict-repeat (lst)
  "Predicts the next repeated operation based on the input list LST."
  (let* ((lst lst)
         (latest-val-pos (cl-position (car lst) lst :start 1))
         repeat-start-pos
         repeat-end-pos)
    (if (null latest-val-pos) ; in the case car of LST does not appear in cdr of LST
        (user-error "Cannot predict repetitive operation.")
      (setq repeat-end-pos (length (yadmacro-prefix-matched-sublist
                                    (cl-subseq lst 0 latest-val-pos)
                                    (cl-subseq lst latest-val-pos))))
      (setq repeat-start-pos (+ latest-val-pos
                                repeat-end-pos))
      (cons (list (cl-subseq lst
                             repeat-end-pos
                             repeat-start-pos)
                  (append (cl-subseq lst repeat-end-pos latest-val-pos)
                          (cl-subseq lst 0 repeat-end-pos)))
            (list repeat-end-pos)))))

(defun yadmacro-split-seq-if (test lst)
  (let (beg end)
    (when (setq beg (cl-position-if     test lst :start 0))
      (setq end (or (cl-position-if-not test lst :start beg) (length lst)))
      (cons (cl-subseq lst beg end)
            (yadmacro-split-seq-if test (cl-subseq lst end))))))

(defun yadmacro-position-subseq (lst sub)
  (let ((pos 0)
        (continue-flag t)
        res)
    (while (and continue-flag
                (setq pos (cl-position (car sub) lst :start pos)))
      (cond ((equal (cl-subseq lst pos (+ pos (length sub)))
                    sub)
             (setq res pos)
             (setq continue-flag nil))
            (t
             (cl-incf pos))))
    res))

(defun yadmacro-get-numbers-and-position (lst)
  (let* ((splitted (yadmacro-split-seq-if 'identity lst))
         (numbers (mapcar (lambda (l)
                            (apply 'cl-concatenate 'string
                                   (mapcar 'string l)))
                          splitted)))
    (cl-mapcar 'list
               (mapcar #'(lambda (sub) (yadmacro-position-subseq lst sub))
                       splitted)
               (mapcar #'(lambda (n) (length n)) numbers)
               (mapcar 'string-to-number numbers))))

(defun yadmacro-get-incremented-sequence (lst)
  (setq lst (mapcar 'reverse lst))
  ;; 数字以外nilに変更
  (let* ((lst1  (yadmacro-get-numbers-and-position
                 (mapcar 'yadmacro-is-number (nth 0 lst))))
         (lst2 (yadmacro-get-numbers-and-position
                (mapcar 'yadmacro-is-number (nth 1 lst))))
         (next-number
          (cl-mapcar 'list              ; 位置情報もくっつけとく。
                     lst1
                     (cl-mapcar '+      ; 足すと次の数字になって↑↑
                                (mapcar 'cl-third lst1)
                                (mapcar (lambda (e)
                                          (* yadmacro-repeat-count e)) ; 連続実行の場合は実行回数をかけて↑↑
                                        (cl-mapcar '- ; 差を出して↑↑
                                                   (mapcar 'cl-third lst1)
                                                   (mapcar 'cl-third lst2)))
                                )))
         (result-seq (cl-copy-list (car lst))))
    (dolist (l next-number) ; 繰り返し1つの中に複数数字がある場合に備えて
      (let ((chars (cl-map 'list
                           'identity
                           (substring (format "000000000000000000%d" (max 0 (cadr l))) ; 桁数維持
                                      (- (cadar l))))))
        (dotimes (n (cadar l))
          (setf (nth (+ n (caar l)) result-seq) (nth n chars)))))
    result-seq ; ←これが連番の増えたver
    ))

(defun yadmacro-get-key-list ()
  (let ((lst (reverse (append (recent-keys) nil)))
        loop-elm
        loop-all
        input-count
        result
        match-pos)
    ;; 繰り返しとみなさないものを除外：
    ;; 直近のyadmacroキーを除外した上で、
    (while (and (setq match-pos (cl-position last-command-event lst :test 'equal))
                (= match-pos 0))
      (setq lst (cdr lst)))
    ;; 最後にyadmacroキーを押した時以降の入力を探索対象に。
    ;; => yadmacroキーを跨いで繰り返しとみなさない
    (setq lst (cl-subseq lst 0
                         (cl-position last-command-event lst :test 'equal)))
    ;; 繰り返しを探す
    (cl-multiple-value-setq (loop-all input-count)
      (yadmacro-detect-repetitive-pattern lst))

    (setq loop-elm (reverse (nth -1 loop-all)))

    ;; 数字が入ってたら連番増やす
    (setq result (cond ((cl-find-if 'yadmacro-is-number loop-elm)
                        (when yadmacro-printf-debug (message "%s" loop-all))
                        (yadmacro-get-incremented-sequence loop-all))
                       (t
                        loop-elm)))
    ;; 繰り返しを予測した場合の最初のyadmacroキーの時のみ繰り返し要素の一部のみ実行
    (cond ((and (= yadmacro-repeat-count 1)
                (< 0 input-count))
           (nthcdr input-count result))
          (t result))))

;;;###autoload
(defun yadmacro ()
  "Detect repetitive key operations and execute them.
If the key operations include number incrementation (or
decrementation), then repeat the incrementation (or
decrementation)."
  (interactive)
  (cond ((equal real-last-command this-command)
         (cl-incf yadmacro-repeat-count))
        (t
         (setq yadmacro-repeat-count 1)))
  (when yadmacro-printf-debug
    (message "lc:%s tc:%s lce:%c tck:%s lce:%c lie:%c lef:%s"
             real-last-command this-command last-command-event
             (this-command-keys)
             last-command-event
             last-input-event
             last-event-frame))
  (let ((lst (yadmacro-get-key-list)))
    (cond ((not lst)
           (user-error "No repetitive operation found."))
          ((not nil)
           (when yadmacro-printf-debug (message "Repeat：%s" lst))
           (execute-kbd-macro (apply 'vector lst))))))

;;;###autoload
(define-minor-mode yadmacro-mode
  "Yet Another Dynamic Macro"
  :group 'ydmacro
  :lighter yadmacro-mode-lighter
  (if yadmacro-mode
      (define-key yadmacro-mode-map (kbd yadmacro-key) 'yadmacro)
    (define-key yadmacro-mode-map (kbd yadmacro-key) nil)))

(defun yadmacro-mode-maybe ()
  "What buffer `yadmacro-mode' prefers."
  (when (and (not (minibufferp (current-buffer)))
             (if yadmacro-use-disable-list
                 (not (memq major-mode yadmacro-disable-modes))
               (memq major-mode yadmacro-enable-modes))
             (yadmacro-mode 1))))

;;;###autoload
(define-globalized-minor-mode global-yadmacro-mode yadmacro-mode
  yadmacro-mode-maybe
  :group 'yadmacro)

(provide 'yadmacro)
;;; yadmacro.el ends here
