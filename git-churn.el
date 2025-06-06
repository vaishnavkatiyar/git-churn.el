;;; git-churn.el --- Highlight high-churn lines using Git history -*- lexical-binding: t; -*-

;; Author: Vaishnav Katiyar
;; Version: 0.1
;; Package-Requires: ((emacs "25.1"))
;; Keywords: git, vc, churn, highlight
;; URL: https://github.com/vaishnavkatiyar/git-churn.el

;;; Commentary:

;; This package highlights lines in a buffer based on how frequently they've changed in Git history.
;; It uses `git log -L` to track how many commits have modified each line, giving a sense of churn.
;; You can visualize the entire file or a specific line range.
;;
;; High churn areas are useful indicators of unstable or evolving code.
;; Each line is colored on a heatmap from green (low churn) to red (high churn),
;; with an inline suffix like `⟶ 5x` showing how many commits have touched that line.

;;; Code:

(defun git-churn--collect-line-changes (&optional start-line end-line)
  "Return list of (line-number . (count . commits)) using Git history.
START-LINE and END-LINE optionally limit the analysis to a range of lines.
Also logs commit hashes for each line to *Messages* buffer."
  (let ((file (buffer-file-name))
        (total-lines (count-lines (point-min) (point-max)))
        (results '()))
    (when (and file (vc-backend file))
      (let ((from (or start-line 1))
            (to (or end-line total-lines)))
        (dotimes (i (1+ (- to from)))
          (let* ((line (+ from i))
                 (cmd (format "git log -L %d,%d:%s --pretty=oneline"
                              line line (shell-quote-argument file)))
                 (commits '()))
            (with-temp-buffer
              (let ((exit-code (call-process-shell-command cmd nil t)))
                (when (eq exit-code 0)
                  (goto-char (point-min))
                  (while (re-search-forward "^\\([a-f0-9]\\{7,\\}\\)" nil t)
                    (push (match-string 1) commits)))))
            (let ((count (length commits)))
              (message "Line %d → commit count: %d" line count)
              (when (> count 0)
                (message "Commits for line %d:\n%s"
                         line
                         (mapconcat (lambda (hash) (format "  %s" hash))
                                    (reverse commits) "\n")))
              (push (cons line (cons count (reverse commits))) results))))))
    (reverse results)))

(defun git-churn--max-count (data)
  "Return the max count from list of (line . (count . commits))."
  (if data
      (apply #'max (mapcar (lambda (entry) (car (cdr entry))) data))
    1.0)) ;; Avoid divide-by-zero if list is empty

(defun git-churn--score-color (score)
  "Return a color hex string for a normalized SCORE between 0.0 and 1.0.
Higher scores (more churn) are red, lower scores are green."
  (let* ((clamped (max 0.0 (min 1.0 score)))
         (red (floor (* clamped 255)))
         (green (floor (* (- 1.0 clamped) 255))))
    (format "#%02x%02x00" red green)))

(defun git-churn--highlight-lines (line-changes)
  "Apply heatmap highlights and annotations to LINE-CHANGES.
Each entry is (line . (count . commits))."
  (let ((max (float (git-churn--max-count line-changes))))
    (save-excursion
      (git-churn-clear-overlays)
      (dolist (entry line-changes)
        (let* ((line (car entry))
               (count (car (cdr entry)))
               (score (/ count max))
               (color (git-churn--score-color score)))
          (goto-char (point-min))
          (forward-line (1- line))
          (let ((overlay (make-overlay (line-beginning-position) (line-end-position))))
            (overlay-put overlay 'face `(:background ,color))
            (overlay-put overlay 'git-churn t))
          (let ((eol (line-end-position))
                (count-text (format "  ⟶ %dx" count)))
            (let ((suffix-ov (make-overlay eol eol)))
              (overlay-put suffix-ov 'after-string
                           (propertize count-text 'face '(:foreground "gray70" :slant italic)))
              (overlay-put suffix-ov 'git-churn t))))))))

(defun git-churn--parse-range (range)
  "Parse RANGE string into a cons cell (START . END).
Handles single lines like \"10\" and ranges like \"10-20\". Returns nil on invalid input."
  (cond
   ((not range) nil)
   ((string-match "^\\([0-9]+\\)-\\([0-9]+\\)$" range)
    (let ((start (string-to-number (match-string 1 range)))
          (end (string-to-number (match-string 2 range))))
      (cons start end)))
   ((string-match "^\\([0-9]+\\)$" range)
    (let ((line (string-to-number (match-string 1 range))))
      (cons line line)))
   (t
    (message "Invalid line range: %s" range)
    nil)))

;;;###autoload
(defun git-churn-visualize-buffer (&optional range)
  "Highlight Git churn in the current buffer.
If RANGE is provided (e.g., \"10\" or \"10-20\"), restrict analysis to that line span."
  (interactive
   (list
    (read-string "Line range (e.g., 10-20 or 15, leave blank for full): ")))
  (let* ((parsed (git-churn--parse-range (string-trim range)))
         (start (car parsed))
         (end (cdr parsed))
         (data (git-churn--collect-line-changes start end)))
    (message "Highlighted %d lines." (length data))
    (git-churn--highlight-lines data)))

;;;###autoload
(defun git-churn-clear-overlays ()
  "Remove all Git churn overlays in the current buffer."
  (interactive)
  (remove-overlays (point-min) (point-max) 'git-churn t))

(provide 'git-churn)

;;; git-churn.el ends here