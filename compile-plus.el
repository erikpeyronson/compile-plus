;;; compile-plus.el --- Manage and navigate projects in Emacs easily -*- lexical-binding: t -*-

;; Copyright © 2018 Bozhidar Batsov <bozhidar@batsov.com>

;; Author: Erik Peyronson <erik.peyronson@gmail.com>
;; URL: https://github.com/erikpeyronson/compile-plus
;; Keywords: project, convenience
;; Version: 
;; Package-Requires: 

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;; This library provides commands and helper functions for interactively compiling
;; and automatically generating compile commands within emacs

(defvar compile-plus-make-command-history nil)
"History of flags and target used in `compile-plus-make-above-interactive"
(eval-after-load "savehist" '(add-to-list 'savehist-additional-variables 'my-make-command-history))

;; code
(defun compile-plus-generate-c++-compile-command (flags target)
  "Generates a compile command string suitable for building c++ projects
if the active buffer is visiting a file, look for the nearest
above makefile.

If no makefile is found generate a g++ string
suitable for setting `compile-command' for `c++ mode' if the
buffer is visiting a file."
  (interactive)
  (when (buffer-file-name)
    (if (setq makefile-path (compile-plus-get-above-makefile))
        (set (make-local-variable 'compile-command)
             (format "make %s -f %s %s" flags makefile-path target))
      (set
       (make-local-variable 'compile-command)
       (format "g++ %s -o %s %s "
               compile-plus-cxx-standard compile-plus-cxx-flags
               (file-name-base buffer-file-name)
               (buffer-name))))))

(defun compile-plus-make-above-interactive ()
  "Run make with the above makefile, promt user for flags and target"
  (interactive)
  (compile-plus-make-above (read-from-minibuffer
                  (format "make " (car compile-plus-make-command-history))
                  (car compile-plus-make-command-history)
                  nil
                  nil
                  'compile-plus-make-command-history)))

(defun compile-plus-make-above-single-testcase ()
  "Run make with the above makefile, prompt user for flags"
  (interactive)
  (compile-plus-make-above-single-test-case (read-from-minibuffer
                                  (format "make (current testcase)" (car compile-plus-make-command-history))
                                  (car compile-plus-make-command-history)
                                  nil
                                  nil
                                  'compile-plus-make-command-history)))

(defun compile-plus-get-above-makefile ()
  "Get the absolute path to the closest above Makefile. 
returns nil if no Makefile is found "
  (let ((dir (locate-dominating-file "." "Makefile")))
    (if dir
	(concat dir "Makefile")
      nil)))

(defun compile-plus-make-above (extra-flags)
  " Run make with the above makefile 
EXTRA-FLAGS contains flags that should be passed to make"
  (compile (format "make -f %s %s" (compile-plus-get-above-makefile) extra-flags)))


(defun compile-plus-get-gtest-group-and-testcase ()
  "Get Testgroup.Testcase from the function at point"
  (save-excursion
    (c-beginning-of-defun)
    (let ((str (string-trim-right (thing-at-point 'line t))))
      (when (string-match "^TEST_F(\\(.*\\), \\(.*\\)) {$" str)
        (setq test-group (match-string 1 str))
        (setq test-case (match-string 2 str)))
      (format "%s.%s" test-group test-case))))

(defun compile-plus-make-above-single-testcase ()
  "run test case above with the above makefile"
  (interactive)
  (compile-plus-make-above (format "RUN_ARGS=--gtest_filter=%s test" (compile-plus-get-gtest-group-and-testcase))))

(provide 'compile-plus)
;; compiile-plus.el ends here
