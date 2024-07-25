;;; clojure-ts-mode-font-lock-test.el --- Clojure TS Mode: font lock test suite  -*- lexical-binding: t; -*-

;; Copyright © 2022-2024 Danny Freeman

;; This file is not part of GNU Emacs.

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

;; The unit test suite of Clojure TS Mode

(require 'clojure-ts-mode)
(require 'cl-lib)
(require 'buttercup)

;; (use-package buttercup)

;;;; Utilities

(defmacro with-fontified-clojure-ts-buffer (content &rest body)
  "Evaluate BODY in a temporary buffer with CONTENT."
  (declare (debug t)
           (indent 1))
  `(with-clojure-ts-buffer ,content
                           (font-lock-ensure)
                           (goto-char (point-min))
                           ,@body))

(defun clojure-ts-get-face-at (start end content)
  "Get the face between START and END in CONTENT."
  (with-fontified-clojure-ts-buffer content
    (let ((start-face (get-text-property start 'face))
          (all-faces (cl-loop for i from start to end collect (get-text-property
                                                               i 'face))))
      (if (cl-every (lambda (face) (eq face start-face)) all-faces)
          start-face
        'various-faces))))

(defun expect-face-at (content start end face)
  "Expect face in CONTENT between START and END to be equal to FACE."
  (expect (clojure-ts-get-face-at start end content) :to-equal face))

(defun expect-faces-at (content &rest faces)
  "Expect FACES in CONTENT.

FACES is a list of the form (content (start end expected-face)*)"
  (dolist (face faces)
    (apply (apply-partially #'expect-face-at content) face)))

(defmacro when-fontifying-it (description &rest tests)
  "Return a buttercup spec.

TESTS are lists of the form (content (start end expected-face)*).  For each test
check that each `expected-face` is found in `content` between `start` and `end`.

DESCRIPTION is the description of the spec."
  (declare (indent 1))
  `(it ,description
     (dolist (test (quote ,tests))
       (apply #'expect-faces-at test))))

;;;; Font locking

(describe "clojure-ts-mode-syntax-table"
  (when-fontifying-it "should handle any known def form"
    ("(def a 1)" (2 4 font-lock-keyword-face))
    ("(defonce a 1)" (2 8 font-lock-keyword-face))
    ("(defn a [b])" (2 5 font-lock-keyword-face))
    ("(defmacro a [b])" (2 9 font-lock-keyword-face))
    ("(definline a [b])" (2 10 font-lock-keyword-face))
    ("(defmulti a identity)" (2 9 font-lock-keyword-face))
    ("(defmethod a :foo [b] (println \"bar\"))" (2 10 font-lock-keyword-face))
    ("(defprotocol a (b [this] \"that\"))" (2 12 font-lock-keyword-face))
    ("(definterface a (b [c]))" (2 13 font-lock-keyword-face))
    ("(defrecord a [b c])" (2 10 font-lock-keyword-face))
    ("(deftype a [b c])" (2 8 font-lock-keyword-face))
    ("(defstruct a :b :c)" (2 10 font-lock-keyword-face))
    ("(deftest a (is (= 1 1)))" (2 8 font-lock-keyword-face))


  ;; TODO: copied from clojure-mode, but failing
  ;; ("(defne [x y])" (2 6 font-lock-keyword-face))
  ;; ("(defnm a b)" (2 6 font-lock-keyword-face))
  ;; ("(defnu)" (2 6 font-lock-keyword-face))
  ;; ("(defnc [a])" (2 6 font-lock-keyword-face))
  ;; ("(defna)" (2 6 font-lock-keyword-face))
  ;; ("(deftask a)" (2 8 font-lock-keyword-face))
  ;; ("(defstate a :start \"b\" :stop \"c\")" (2 9 font-lock-keyword-face))

    )

  (when-fontifying-it "variable-def-string-with-docstring"
    ("(def foo \"usage\" \"hello\")"
     (10 16 font-lock-doc-face)
     (18 24 font-lock-string-face))

    ("(def foo \"usage\" \"hello\"   )"
     (18 24 font-lock-string-face))

    ("(def foo \"usage\" \n  \"hello\")"
     (21 27 font-lock-string-face))

    ("(def foo \n  \"usage\" \"hello\")"
     (13 19 font-lock-doc-face))

    ("(def foo \n  \"usage\" \n  \"hello\")"
     (13 19 font-lock-doc-face)
     (24 30 font-lock-string-face))

    ("(def test-string\n  \"this\\n\n  is\n  my\n  string\")"
     (20 24 font-lock-string-face)
     (25 26 font-lock-string-face)
     (27 46 font-lock-string-face)))

  (when-fontifying-it "variable-def-with-metadata-and-docstring"
    ("^{:foo bar}(def foo \n  \"usage\" \n  \"hello\")"
     (13 15 font-lock-keyword-face)
     (17 19 font-lock-variable-name-face)
     (24 30 font-lock-doc-face)
     (35 41 font-lock-string-face)))

  (when-fontifying-it "defn-with-metadata-and-docstring"
    ("^{:foo bar}(defn foo \n  \"usage\" \n [] \n \"hello\")"
     (13 16 font-lock-keyword-face)
     (18 20 font-lock-function-name-face)
     (25 31 font-lock-doc-face)
     (40 46 font-lock-string-face))))