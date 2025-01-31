;; TradeNest Main Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u401))
(define-constant err-listing-closed (err u403))

;; Data Structures
(define-map listings
  { listing-id: uint }
  {
    owner: principal,
    title: (string-utf8 100),
    description: (string-utf8 500),
    category: (string-utf8 50),
    location: (string-utf8 100),
    status: (string-utf8 20),
    created-at: uint
  }
)

(define-map offers 
  { offer-id: uint }
  {
    listing-id: uint,
    from: principal,
    offer-items: (list 5 (string-utf8 100)),
    status: (string-utf8 20),
    created-at: uint
  }
)

(define-map user-ratings
  { user: principal }
  {
    total-rating: uint,
    rating-count: uint
  }
)

;; Data Variables
(define-data-var listing-nonce uint u0)
(define-data-var offer-nonce uint u0)

;; Public Functions
(define-public (create-listing 
  (title (string-utf8 100))
  (description (string-utf8 500))
  (category (string-utf8 50))
  (location (string-utf8 100)))
  (let
    ((listing-id (+ (var-get listing-nonce) u1)))
    (map-set listings
      { listing-id: listing-id }
      {
        owner: tx-sender,
        title: title,
        description: description,
        category: category,
        location: location,
        status: "active",
        created-at: block-height
      }
    )
    (var-set listing-nonce listing-id)
    (ok listing-id)
  )
)

(define-public (make-offer 
  (listing-id uint)
  (offer-items (list 5 (string-utf8 100))))
  (let
    ((offer-id (+ (var-get offer-nonce) u1))
     (listing (unwrap! (map-get? listings {listing-id: listing-id}) err-not-found)))
    (asserts! (is-eq (get status listing) "active") err-listing-closed)
    (map-set offers
      { offer-id: offer-id }
      {
        listing-id: listing-id,
        from: tx-sender,
        offer-items: offer-items,
        status: "pending",
        created-at: block-height
      }
    )
    (var-set offer-nonce offer-id)
    (ok offer-id)
  )
)

(define-public (accept-offer (offer-id uint))
  (let
    ((offer (unwrap! (map-get? offers {offer-id: offer-id}) err-not-found))
     (listing (unwrap! (map-get? listings {listing-id: (get listing-id offer)}) err-not-found)))
    (asserts! (is-eq tx-sender (get owner listing)) err-unauthorized)
    (map-set offers
      { offer-id: offer-id }
      (merge offer { status: "accepted" })
    )
    (map-set listings
      { listing-id: (get listing-id offer) }
      (merge listing { status: "completed" })
    )
    (ok true)
  )
)

(define-public (rate-user (user principal) (rating uint))
  (let
    ((current-rating (default-to
      { total-rating: u0, rating-count: u0 }
      (map-get? user-ratings { user: user }))))
    (asserts! (and (>= rating u1) (<= rating u5)) (err u400))
    (map-set user-ratings
      { user: user }
      {
        total-rating: (+ (get total-rating current-rating) rating),
        rating-count: (+ (get rating-count current-rating) u1)
      }
    )
    (ok true)
  )
)

;; Read Only Functions
(define-read-only (get-listing (listing-id uint))
  (map-get? listings {listing-id: listing-id})
)

(define-read-only (get-offer (offer-id uint))
  (map-get? offers {offer-id: offer-id})
)

(define-read-only (get-user-rating (user principal))
  (map-get? user-ratings {user: user})
)
