;;; codespaces.el --- Connect to GitHub Codespaces via TRAMP  -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Patrick Thomson and Bas Alberts

;; Author: Patrick Thomson <patrickt@github.com>
;; URL: https://github.com/patrickt/codespaces.el
;; Package-Version: 0.1
;; Package-Requires: ((emacs "28.1") (dash "2.19"))
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
;; via TRAMP in Emacs. It also will provide a completing-read interface
;; to select codespaces.

;; This package works by registering a new "ghcs" method in tramp-methods.

;;; Code:

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

(defun codespaces--get-codespaces ()
  (letrec
      ((gh-invocation "gh codespace list --json name,displayName,repository,state,gitStatus,lastUsedAt")
       (codespace-json (shell-command-to-string gh-invocation)))
    (json-parse-string codespace-json)))

(defun codespaces--munge (json)
  (-map (lambda (n) (list (gethash "name" n) (gethash "repository" n))) json))

(defun codespaces--annotate (s)
  (let ((item (assoc s minibuffer-completion-table)))
    (when item (concat "  -- " (nth 1 item)))))

(defun codespaces--complete ()
  (interactive)
  (letrec
      ((json (codespaces--get-codespaces))
       (valid-names (codespaces--munge json)))
    (let ((completion-extra-properties '(:annotation-function codespaces--annotate)))
      (completing-read "Please select a codespace: " valid-names))))

(defun codespaces-connect ()
  "Connect to a running codespace."
  (interactive)
  (let (cs (codespaces--complete))
    (find-file (format "/ghcs:patrickt-git:/workspaces"))))

(provide 'codespaces)

;;; codespaces.el ends here
