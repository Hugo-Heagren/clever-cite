;;; clever-cite.el --- Semi-intelligent quoting for yanked text  -*- lexical-binding: t; -*-

;; Copyright (C) 2025  Hugo Heagren

;; Author: Hugo Heagren <hugo@heagren.com>
;; Keywords: text

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides a simple and extensible framework for killing
;; text out of a buffer and inserting relevant quotation and citation
;; markers when it is yanked into another buffer.

;; To use:
;; - Use file-local variables, hooks or mode functions to
;;   automatically `clever-cite-cite-key' and `clever-cite-ref'.
;; - Use mode hooks to set an appropriate value for
;;  `clever-cite-quote-function' in each mode where you might input
;;   quoted text. Common examples include LaTeX modes and Org mode.
;; - Set `kill-transform-function' to `clever-cite-kill-transform' in
;;   all modes/files/etc. from which you might want to kill text which
;;   can later be yanked as a quote.
;; - profit!

;;; Code:

(defvar-local clever-cite-cite-key nil
  "Method for getting citation key.

Can be either a string (the key), or a function called with no arguments
which returns the key as a string.

You probably don't want to set this variable explicitly from Lisp,
instead use a file-local variable, hook or mode function to set it
automatically.")
;;;###autoload(put 'clever-cite-cite-key 'safe-local-variable (lambda (val) (or (stringp val) (functionp val))))

(defun clever-cite-get-cite-key ()
  "Get the key for the current buffer."
  (if (functionp clever-cite-cite-key)
      (funcall clever-cite-cite-key)
    clever-cite-cite-key))

(defvar-local clever-cite-ref nil
  "Method for getting citation reference.

Can be either nil, a string (the reference), or a function called with
no arguments which returns the reference or nil.

You probably don't want to set this variable explicitly, instead use a
file-local variable, hook or mode function to set it automatically.")
;;;###autoload(put 'clever-cite-ref 'safe-local-variable (lambda (val) (or (stringp val) (functionp val))))

(defun clever-cite-get-ref ()
  "Get the ref for the current buffer."
  (if (functionp clever-cite-ref)
      (funcall clever-cite-ref)
    clever-cite-ref))

(defvar-local clever-cite-quote-function nil
  "Function for formatting inserted quotes.

This should be set to a function which takes a stribg (the qoute), a
citation key (without any leading @) and optionally a reference
string (for the page or section number). If the function returns a
string, that string is inserted verbatim. If it returns t, that means
the function has handled the insertion and clever-cite doesn't need to
do anything. Any other return value results in an error.")

(defun clever-cite-yank-handler (str)
  "Function for use in yank-handler property on STR.

Get value of `clever-cite-quote-function', cite-key (from
`clever-cite-cite-key' property of STR), and optionally ref (from
`clever-cite-ref' property) and then call the function with STR,
CITE-KEY and REF (if non-nil) as arguments.

If the call returns a string, insert it verbatim. If it returns t,
assume the function has handled insertion. Any other return value
results in an error."
  (if-let* ((fun clever-cite-quote-function)
	    (cite-key (get-text-property 0 'clever-cite-cite-key str))
	    (result (funcall
		     fun str cite-key
		     (get-text-property 0 'clever-cite-ref str))))
      (cond
       ((stringp result) (insert result))
       ;; Insertion already handled, no need for further action
       ((eq result t))
       (t (error "Invalid return value from `clever-cite-quote-function' %s"
	      clever-cite-quote-function)))
    ;; No special handling, just insert text
    (insert str)))

(defun clever-cite-kill-transform (str)
  "Propertize STR with cite-key and ref.

cite-key and ref are obtained by running `clever-cite-get-cite-key' and
`clever-cite-get-ref' respectively."
  (if-let* ((cite-key (clever-cite-get-cite-key)))
      (propertize
       str
       ;; Local value of variable
       'clever-cite-cite-key cite-key
       'clever-cite-ref      (clever-cite-get-ref)
       ;; TODO Take care of UNDO
       'yank-handler         '(clever-cite-yank-handler))
    ;; Just return string unchanges
    str))

(provide 'clever-cite)
;;; clever-cite.el ends here
