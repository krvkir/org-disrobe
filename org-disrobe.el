;;; org-disrobe.el --- Show original string behind perttified symbol at point in Org mode -*- lexical-binding: t -*-

;; Copyright (C) 2026 krvkir

;; Author: krvkir <krvkir@gmail.com>
;; Version: 0.1
;; Keywords: org, tools
;; Package-Requires: ((emacs "29.1") (org "9.1"))
;; URL: https://github.com/krvkir/org-disrobe

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
;; Provides an editable mindmap visualization system within org-mode buffers.
;; Implements core data structures, region detection, parsing,
;; rendering (top, centered, with optional compaction), alignment, structural editing,
;; layout switching, and configuration via custom variables and text properties.

;;; Code:

(defvar-local org-disrobe--bounds nil
  "Current bounds of the unprettified entity at point.")

(defun org-disrobe--post-command ()
  "Unprettify the Org entity at point."
  ;; 1. Re-prettify the previous entity if point moved out of it.
  (when (and org-disrobe--bounds
             (or (< (point) (car org-disrobe--bounds))
                 (> (point) (cdr org-disrobe--bounds))))
    (let* ((start-marker (car org-disrobe--bounds))
           (end-marker (cdr org-disrobe--bounds))
           (start (marker-position start-marker))
           (end (marker-position end-marker)))
      ;; Disassociate markers to prevent leaks in buffer's marker list
      (set-marker start-marker nil)
      (set-marker end-marker nil)
      (setq org-disrobe--bounds nil)
      (when (and start end)
        (font-lock-flush start end))))

  ;; 2. Detect composition at point or immediately before it (right-edge).
  (when (and (derived-mode-p 'org-mode)
             org-pretty-entities)
    (let ((comp (or (find-composition (point))
                    (and (> (point) (point-min))
                         (find-composition (1- (point)))))))
      (when comp
        (let ((start (car comp))
              (end (cadr comp)))
          ;; Ensure the point is within the bounds or immediately after
          (when (and (>= (point) start)
                     (<= (point) end))
            (with-silent-modifications
              (setq org-disrobe--bounds
                    (cons (copy-marker start) (copy-marker end)))
              (remove-text-properties start end '(composition nil)))))))))

;;;###autoload
(define-minor-mode org-disrobe-mode
  "Unprettify Org pretty entities when point is on them."
  :lighter " Org Disrobe"
  :group 'org
  (if org-disrobe-mode
      (add-hook 'post-command-hook #'org-disrobe--post-command nil t)
    (remove-hook 'post-command-hook #'org-disrobe--post-command t)
    ;; Clean up any remaining unprettified bounds
    (when org-disrobe--bounds
      (let* ((start-marker (car org-disrobe--bounds))
             (end-marker (cdr org-disrobe--bounds))
             (start (marker-position start-marker))
             (end (marker-position end-marker)))
        (set-marker start-marker nil)
        (set-marker end-marker nil)
        (setq org-disrobe--bounds nil)
        (when (and start end)
          (font-lock-flush start end))))))

;;; org-disrobe.el ends here
