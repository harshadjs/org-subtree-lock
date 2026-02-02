;;; org-subtree-lock.el --- Read-only protection for Org subtrees -*- lexical-binding: t; -*-

;; Author: Harshad Shirwadkar <harshadshirwadkar@gmail.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "26.1"))
;; Keywords: outlines, hypermedia, convenience
;; URL: https://github.com/harshadjs/org-subtree-lock

;;; Commentary:

;; This package provides a mechanism to lock specific Org-mode subtrees.
;; When a subtree is tagged with a specific tag (defaulting to "locked"),
;; the text properties are modified to make that subtree read-only.
;; Use `my/org-toggle-subtree-lock` to toggle the state.

;;; Code:

(require 'org-element)

(defgroup org-subtree-lock nil
  "Customizations for locking Org-mode subtrees."
  :group 'org
  :prefix "org-subtree-lock-")

(defcustom org-subtree-lock-tag "locked"
  "The Org-mode tag used to trigger read-only protection on a subtree."
  :type 'string
  :group 'org-subtree-lock)

;;;###autoload
(defun org-subtree-lock-toggle ()
  "Add/remove the configured lock tag and toggle read-only protection for the subtree."
  (interactive)
  (save-excursion
    (org-back-to-heading t)
    (let* ((element (org-element-at-point))
           (begin (org-element-property :begin element))
           (end (org-element-property :end element))
           (has-tag (member org-subtree-lock-tag (org-get-tags nil t))))

      (let ((inhibit-read-only t))
        (if has-tag
            (progn
              (org-toggle-tag org-subtree-lock-tag 'off)
              (remove-text-properties begin end '(read-only nil))
              (message "Subtree Unlocked: :%s: removed." org-subtree-lock-tag))
          (progn
            (org-toggle-tag org-subtree-lock-tag 'on)
            (setq end (org-element-property :end (org-element-at-point)))
            (add-text-properties begin end '(read-only t))
            (message "Subtree Locked: :%s: active." org-subtree-lock-tag)))))))

;;;###autoload
(defun org-subtree-lock-apply-all ()
  "Scan buffer for the lock tag and apply read-only properties."
  (interactive)
  (when (derived-mode-p 'org-mode)
    (save-excursion
      (save-restriction
        (widen)
        (let ((inhibit-read-only t))
          (remove-text-properties (point-min) (point-max) '(read-only nil))
          (org-element-map (org-element-parse-buffer) 'headline
            (lambda (hl)
              (let ((tags (org-element-property :tags hl)))
                (when (member org-subtree-lock-tag tags)
                  (let ((begin (org-element-property :begin hl))
                        (end (org-element-property :end hl)))
                    (add-text-properties begin end '(read-only t)))))))))))
  (message "Org locks applied (Tag: :%s:)." org-subtree-lock-tag))

;;;###autoload
(define-minor-mode org-subtree-lock-mode
  "Minor mode to protect Org subtrees based on tags."
  :lighter " OrgLock"
  (if org-subtree-lock-mode
      (progn
        (org-subtree-lock-apply-all)
        (add-hook 'after-save-hook #'org-subtree-lock-apply-all nil t))
    (let ((inhibit-read-only t))
      (remove-text-properties (point-min) (point-max) '(read-only nil))
      (remove-hook 'after-save-hook #'org-subtree-lock-apply-all t))))

(provide 'org-subtree-lock)
;;; org-subtree-lock.el ends here
