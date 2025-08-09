;; Green Building Certification Smart Contract
;; Blockchain-verified sustainable construction practices
;; Version: 1.0.0

;; Error codes
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-SCORE (err u103))
(define-constant ERR-INVALID-STATUS (err u104))
(define-constant ERR-EXPIRED-CERT (err u105))
(define-constant ERR-INSUFFICIENT-SCORE (err u106))

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MIN-CERTIFICATION-SCORE u70)
(define-constant CERT-VALIDITY-BLOCKS u144000) ;; ~1 year (assuming 10 min blocks)

;; Certification levels
(define-constant CERT-BRONZE u70)
(define-constant CERT-SILVER u80)
(define-constant CERT-GOLD u90)
(define-constant CERT-PLATINUM u95)

;; Building status constants
(define-constant STATUS-PENDING u0)
(define-constant STATUS-UNDER-REVIEW u1)
(define-constant STATUS-CERTIFIED u2)
(define-constant STATUS-EXPIRED u3)
(define-constant STATUS-REVOKED u4)

;; Data structures
(define-map buildings
  { building-id: uint }
  {
    owner: principal,
    name: (string-ascii 100),
    location: (string-ascii 200),
    construction-date: uint,
    certification-date: uint,
    expiry-block: uint,
    status: uint,
    score: uint,
    level: (string-ascii 20),
    verified-by: principal,
    energy-efficiency: uint,
    water-conservation: uint,
    material-sustainability: uint,
    indoor-air-quality: uint,
    innovation-points: uint
  }
)

(define-map authorized-verifiers
  { verifier: principal }
  { 
    name: (string-ascii 100),
    license-number: (string-ascii 50),
    authorized-date: uint,
    is-active: bool
  }
)

(define-map building-documents
  { building-id: uint, doc-type: (string-ascii 50) }
  {
    hash: (buff 32),
    uploaded-by: principal,
    upload-date: uint,
    verified: bool
  }
)

;; Data variables
(define-data-var next-building-id uint u1)
(define-data-var total-certified-buildings uint u0)

;; Public functions

;; Register a new building for certification
(define-public (register-building 
    (name (string-ascii 100))
    (location (string-ascii 200))
    (construction-date uint))
  (let ((building-id (var-get next-building-id)))
    (asserts! (> (len name) u0) ERR-INVALID-STATUS)
    (asserts! (> (len location) u0) ERR-INVALID-STATUS)
    (asserts! (<= construction-date block-height) ERR-INVALID-STATUS)
    
    (map-set buildings
      { building-id: building-id }
      {
        owner: tx-sender,
        name: name,
        location: location,
        construction-date: construction-date,
        certification-date: u0,
        expiry-block: u0,
        status: STATUS-PENDING,
        score: u0,
        level: "NONE",
        verified-by: CONTRACT-OWNER,
        energy-efficiency: u0,
        water-conservation: u0,
        material-sustainability: u0,
        indoor-air-quality: u0,
        innovation-points: u0
      }
    )
    
    (var-set next-building-id (+ building-id u1))
    (ok building-id)
  )
)

;; Add authorized verifier (only contract owner)
(define-public (add-verifier 
    (verifier principal)
    (name (string-ascii 100))
    (license-number (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (is-none (map-get? authorized-verifiers { verifier: verifier })) ERR-ALREADY-EXISTS)
    
    (map-set authorized-verifiers
      { verifier: verifier }
      {
        name: name,
        license-number: license-number,
        authorized-date: block-height,
        is-active: true
      }
    )
    (ok true)
  )
)

;; Submit building assessment scores (only authorized verifiers)
(define-public (submit-assessment
    (building-id uint)
    (energy-efficiency uint)
    (water-conservation uint)
    (material-sustainability uint)
    (indoor-air-quality uint)
    (innovation-points uint))
  (let (
    (building-data (unwrap! (map-get? buildings { building-id: building-id }) ERR-NOT-FOUND))
    (verifier-data (unwrap! (map-get? authorized-verifiers { verifier: tx-sender }) ERR-UNAUTHORIZED))
    (total-score (+ energy-efficiency water-conservation material-sustainability indoor-air-quality innovation-points))
  )
    (asserts! (get is-active verifier-data) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get status building-data) STATUS-PENDING) ERR-INVALID-STATUS)
    (asserts! (and (<= energy-efficiency u25) (<= water-conservation u25) 
                   (<= material-sustainability u25) (<= indoor-air-quality u20)
                   (<= innovation-points u5)) ERR-INVALID-SCORE)
    
    (map-set buildings
      { building-id: building-id }
      (merge building-data {
        energy-efficiency: energy-efficiency,
        water-conservation: water-conservation,
        material-sustainability: material-sustainability,
        indoor-air-quality: indoor-air-quality,
        innovation-points: innovation-points,
        score: total-score,
        status: STATUS-UNDER-REVIEW,
        verified-by: tx-sender
      })
    )
    (ok total-score)
  )
)

;; Issue certification based on assessment
(define-public (issue-certification (building-id uint))
  (let (
    (building-data (unwrap! (map-get? buildings { building-id: building-id }) ERR-NOT-FOUND))
    (verifier-data (unwrap! (map-get? authorized-verifiers { verifier: tx-sender }) ERR-UNAUTHORIZED))
    (score (get score building-data))
    (cert-level (get-certification-level score))
    (expiry-block (+ block-height CERT-VALIDITY-BLOCKS))
  )
    (asserts! (get is-active verifier-data) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get status building-data) STATUS-UNDER-REVIEW) ERR-INVALID-STATUS)
    (asserts! (>= score MIN-CERTIFICATION-SCORE) ERR-INSUFFICIENT-SCORE)
    (asserts! (is-eq tx-sender (get verified-by building-data)) ERR-UNAUTHORIZED)
    
    (map-set buildings
      { building-id: building-id }
      (merge building-data {
        certification-date: block-height,
        expiry-block: expiry-block,
        status: STATUS-CERTIFIED,
        level: cert-level
      })
    )
    
    (var-set total-certified-buildings (+ (var-get total-certified-buildings) u1))
    (ok cert-level)
  )
)

;; Upload document hash for building
(define-public (upload-document
    (building-id uint)
    (doc-type (string-ascii 50))
    (doc-hash (buff 32)))
  (let (
    (building-data (unwrap! (map-get? buildings { building-id: building-id }) ERR-NOT-FOUND))
  )
    (asserts! (or (is-eq tx-sender (get owner building-data))
                  (is-some (map-get? authorized-verifiers { verifier: tx-sender }))) ERR-UNAUTHORIZED)
    
    (map-set building-documents
      { building-id: building-id, doc-type: doc-type }
      {
        hash: doc-hash,
        uploaded-by: tx-sender,
        upload-date: block-height,
        verified: false
      }
    )
    (ok true)
  )
)

;; Verify uploaded document (only verifiers)
(define-public (verify-document
    (building-id uint)
    (doc-type (string-ascii 50)))
  (let (
    (doc-data (unwrap! (map-get? building-documents { building-id: building-id, doc-type: doc-type }) ERR-NOT-FOUND))
    (verifier-data (unwrap! (map-get? authorized-verifiers { verifier: tx-sender }) ERR-UNAUTHORIZED))
  )
    (asserts! (get is-active verifier-data) ERR-UNAUTHORIZED)
    
    (map-set building-documents
      { building-id: building-id, doc-type: doc-type }
      (merge doc-data { verified: true })
    )
    (ok true)
  )
)

;; Renew certification
(define-public (renew-certification
    (building-id uint)
    (new-score uint))
  (let (
    (building-data (unwrap! (map-get? buildings { building-id: building-id }) ERR-NOT-FOUND))
    (verifier-data (unwrap! (map-get? authorized-verifiers { verifier: tx-sender }) ERR-UNAUTHORIZED))
    (cert-level (get-certification-level new-score))
    (expiry-block (+ block-height CERT-VALIDITY-BLOCKS))
  )
    (asserts! (get is-active verifier-data) ERR-UNAUTHORIZED)
    (asserts! (>= new-score MIN-CERTIFICATION-SCORE) ERR-INSUFFICIENT-SCORE)
    (asserts! (or (is-eq (get status building-data) STATUS-CERTIFIED)
                  (is-eq (get status building-data) STATUS-EXPIRED)) ERR-INVALID-STATUS)
    
    (map-set buildings
      { building-id: building-id }
      (merge building-data {
        score: new-score,
        level: cert-level,
        certification-date: block-height,
        expiry-block: expiry-block,
        status: STATUS-CERTIFIED,
        verified-by: tx-sender
      })
    )
    (ok cert-level)
  )
)

;; Read-only functions

(define-read-only (get-building-info (building-id uint))
  (map-get? buildings { building-id: building-id })
)

(define-read-only (get-verifier-info (verifier principal))
  (map-get? authorized-verifiers { verifier: verifier })
)

(define-read-only (get-document (building-id uint) (doc-type (string-ascii 50)))
  (map-get? building-documents { building-id: building-id, doc-type: doc-type })
)

(define-read-only (is-certification-valid (building-id uint))
  (match (map-get? buildings { building-id: building-id })
    building-data (and 
                    (is-eq (get status building-data) STATUS-CERTIFIED)
                    (< block-height (get expiry-block building-data)))
    false
  )
)

(define-read-only (get-total-certified-buildings)
  (var-get total-certified-buildings)
)

(define-read-only (get-next-building-id)
  (var-get next-building-id)
)

;; Private functions

(define-private (get-certification-level (score uint))
  (if (>= score CERT-PLATINUM) "PLATINUM"
  (if (>= score CERT-GOLD) "GOLD"  
  (if (>= score CERT-SILVER) "SILVER"
  (if (>= score CERT-BRONZE) "BRONZE"
  "NONE"))))
)