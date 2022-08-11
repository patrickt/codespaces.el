;;; codespaces.el --- Connect to GitHub Codespaces via TRAMP  -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Patrick Thomson and Bas Alberts

;; Author: Patrick Thomson <patrickt@github.com>
;; URL: https://github.com/patrickt/codespaces.el
;; Package-Version: 0.1
;; Package-Requires: ((emacs "28.1"))
;; Keywords: tramp
;; Created: 2022-08-11

;;; License:

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

;; This package provides support for connecting to GitHub Codespaces
;; via TRAMP in Emacs. It also provides a completing-read interface
;; to select codespaces.

;; This package works by registering a new "ghcs" method in tramp-methods.

;;; Code:

(require 'tramp)

(defun codespaces-setup ()
  "Set up the ghcs tramp-method. Should be called after requiring this package."
  (interactive)
  (unless (executable-find "gh")
    (error "Could not find `gh' program in your PATH."))
  (unless (and (fboundp 'json-available-p) (json-available-p))
    (error "Emacs JSON support not available; your Emacs is too old."))
  (let ((ghcs (assoc "ghcs" tramp-methods))
        (ghcs-methods '((tramp-login-program "gh")
                        (tramp-login-args (("codespace") ("ssh") ("-c") ("%h")))
                        (tramp-remote-shell "/bin/sh")
                        (tramp-remote-shell-login ("-l"))
                        (tramp-remote-shell-args ("-c")))))
    ;; just for debugging the methods
    (if ghcs (setcdr ghcs ghcs-methods)
      (push (cons "ghcs" ghcs-methods) tramp-methods))))

(cl-defstruct codespaces-space name state repository ref)

(defun codespaces-space-from-hashtable (ht)
  (make-codespaces-space
   :name (gethash "name" ht)
   :state (gethash "state" ht)
   :repository (gethash "repository" ht)
   :ref (gethash "ref" (gethash "gitStatus" ht))))

(defun codespaces-space-describe (cs)
  (format " -- %s | %s | %s"
          (codespaces-space-state cs)
          (codespaces-space-repository cs)
          (codespaces-space-ref cs)))

(defun codespaces--get-codespaces ()
  (letrec
      ((gh-invocation "gh codespace list --json name,displayName,repository,state,gitStatus,lastUsedAt")
       (codespace-json (shell-command-to-string gh-invocation)))
    (codespaces--munge (json-parse-string codespace-json))))

(defun codespaces--fold (acc val)
  (let ((cs (codespaces-space-from-hashtable val)))
    (puthash (codespaces-space-name cs) cs acc)
    acc))

(defun codespaces--munge (json)
  (seq-reduce #'codespaces--fold json (make-hash-table :test 'equal)))

(defun codespaces--annotate (s)
  (let ((item (gethash s minibuffer-completion-table)))
    (codespaces-space-describe item)))

(defun codespaces--complete (json)
  (let
      ((completion-extra-properties '(:annotation-function codespaces--annotate))
       (valid-names json))
    (completing-read "Please select a codespace: " valid-names)))

(defun codespaces-connect ()
  "Select a codespace with completing-read and open a Dired browser at /workspaces."
  (interactive)
  (letrec ((json (codespaces--get-codespaces))
           (cs (codespaces--complete json)))
    (find-file (format "/ghcs:%s:/workspaces" cs))))

(provide 'codespaces)

;;; codespaces.el ends here
