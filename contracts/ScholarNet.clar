;; ScholarNet - Academic research and knowledge sharing rewards platform
(define-data-var research-director principal tx-sender)
(define-data-var total-knowledge-credits uint u0)
(define-data-var scholarship-factor uint u65) ;; factor per research contribution
(define-data-var last-peer-review uint u0)

(define-map research-contributions principal uint)
(define-map academic-fields principal (string-utf8 64))
(define-map validated-fields (string-utf8 64) bool)

;; Error codes
(define-constant err-unauthorized-director (err u7600))
(define-constant err-director-already-established (err u7601))
(define-constant err-invalid-knowledge-credits (err u7602))
(define-constant err-no-scholarship-rewards (err u7603))
(define-constant err-no-research-contributions (err u7604))
(define-constant err-invalid-academic-field (err u7605))
(define-constant err-field-not-validated (err u7606))

;; Verify research director authorization
(define-private (is-research-director (caller principal))
  (begin
    (asserts! (is-eq caller (var-get research-director)) err-unauthorized-director)
    (ok true)))

;; Initialize academic research network
(define-public (establish-scholar-network (director principal))
  (begin
    (asserts! (is-none (map-get? research-contributions director)) err-director-already-established)
    (var-set research-director director)
    (ok "ScholarNet academic research network established")))

;; Validate academic field for contribution tracking
(define-public (validate-academic-field (field (string-utf8 64)))
  (begin
    (try! (is-research-director tx-sender))
    (asserts! (> (len field) u0) err-invalid-academic-field)
    (map-set validated-fields field true)
    (ok "Academic field validated for research tracking")))

;; Record research contribution
(define-public (record-research-contribution (knowledge-credits uint) (field (string-utf8 64)))
  (begin
    (asserts! (> knowledge-credits u0) err-invalid-knowledge-credits)
    (asserts! (default-to false (map-get? validated-fields field)) err-field-not-validated)
    
    (let ((current-contributions (default-to u0 (map-get? research-contributions tx-sender))))
      (map-set research-contributions tx-sender (+ current-contributions knowledge-credits))
      (map-set academic-fields tx-sender field)
      (var-set total-knowledge-credits (+ (var-get total-knowledge-credits) knowledge-credits))
      (ok (+ current-contributions knowledge-credits)))))

;; Conduct peer review assessment
(define-public (conduct-peer-review-assessment)
  (begin
    (try! (is-research-director tx-sender))
    (let ((current-review (+ (var-get last-peer-review) u1))
          (total-credits (var-get total-knowledge-credits)))
      (asserts! (> total-credits (var-get last-peer-review)) err-no-scholarship-rewards)
      
      (let ((scholarship-reward-pool (* (var-get scholarship-factor) total-credits)))
        (var-set last-peer-review current-review)
        (ok scholarship-reward-pool)))))

;; Complete scholarly certification and claim rewards
(define-public (complete-scholarly-certification)
  (begin
    (let ((research-credits (default-to u0 (map-get? research-contributions tx-sender))))
      (asserts! (> research-credits u0) err-no-research-contributions)
      
      (let ((total-credits (var-get total-knowledge-credits))
            (base-scholarship-rewards (* (var-get scholarship-factor) research-credits))
            (contribution-ratio (/ (* research-credits u100000) total-credits)))
        
        (let ((final-scholarship-rewards (/ (* contribution-ratio base-scholarship-rewards) u100000)))
          (map-delete research-contributions tx-sender)
          (map-delete academic-fields tx-sender)
          (var-set total-knowledge-credits (- (var-get total-knowledge-credits) research-credits))
          (ok (+ research-credits final-scholarship-rewards)))))))

;; Read-only functions
(define-read-only (get-research-contributions (scholar principal))
  (default-to u0 (map-get? research-contributions scholar)))

(define-read-only (get-academic-field (scholar principal))
  (map-get? academic-fields scholar))

(define-read-only (get-total-knowledge-credits)
  (var-get total-knowledge-credits))

(define-read-only (is-field-validated (field (string-utf8 64)))
  (default-to false (map-get? validated-fields field)))
