;; Community Program Contract
;; Organizes youth basketball leagues and clinics

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-PROGRAM-NOT-FOUND (err u501))
(define-constant ERR-REGISTRATION-NOT-FOUND (err u502))
(define-constant ERR-PROGRAM-FULL (err u503))
(define-constant ERR-INVALID-AGE (err u504))
(define-constant ERR-PAYMENT-REQUIRED (err u505))

;; Data Variables
(define-data-var next-program-id uint u1)
(define-data-var next-registration-id uint u1)

;; Data Maps
(define-map community-programs
  { program-id: uint }
  {
    program-name: (string-ascii 100),
    program-type: (string-ascii 30),
    description: (string-ascii 300),
    age-min: uint,
    age-max: uint,
    max-participants: uint,
    current-participants: uint,
    fee: uint,
    start-date: uint,
    end-date: uint,
    schedule: (string-ascii 200),
    coordinator: principal,
    status: (string-ascii 20),
    court-assignments: (list 4 uint)
  }
)

(define-map program-registrations
  { registration-id: uint }
  {
    program-id: uint,
    participant-name: (string-ascii 100),
    participant-age: uint,
    guardian-name: (string-ascii 100),
    guardian-contact: (string-ascii 100),
    emergency-contact: (string-ascii 100),
    medical-info: (string-ascii 200),
    registration-date: uint,
    payment-status: (string-ascii 20),
    amount-paid: uint,
    registered-by: principal
  }
)

(define-map volunteer-coaches
  { coach: principal }
  {
    name: (string-ascii 100),
    experience-years: uint,
    certifications: (string-ascii 200),
    background-check: bool,
    assigned-programs: (list 5 uint),
    availability: (string-ascii 100),
    contact-info: (string-ascii 100)
  }
)

(define-map program-attendance
  { program-id: uint, session-date: uint }
  {
    scheduled-participants: uint,
    actual-attendance: uint,
    session-notes: (string-ascii 300),
    weather-cancelled: bool,
    makeup-session-scheduled: bool
  }
)

(define-map program-finances
  { program-id: uint }
  {
    total-revenue: uint,
    total-expenses: uint,
    equipment-costs: uint,
    coach-payments: uint,
    facility-costs: uint,
    profit-loss: int
  }
)

;; Public Functions

;; Create a new community program
(define-public (create-program (program-name (string-ascii 100)) (program-type (string-ascii 30)) (description (string-ascii 300)) (age-min uint) (age-max uint) (max-participants uint) (fee uint) (start-date uint) (end-date uint) (schedule (string-ascii 200)) (court-assignments (list 4 uint)))
  (let
    (
      (program-id (var-get next-program-id))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (< age-min age-max) ERR-INVALID-AGE)
    (asserts! (< start-date end-date) ERR-INVALID-AGE)

    ;; Create the program
    (map-set community-programs
      { program-id: program-id }
      {
        program-name: program-name,
        program-type: program-type,
        description: description,
        age-min: age-min,
        age-max: age-max,
        max-participants: max-participants,
        current-participants: u0,
        fee: fee,
        start-date: start-date,
        end-date: end-date,
        schedule: schedule,
        coordinator: tx-sender,
        status: "open",
        court-assignments: court-assignments
      }
    )

    ;; Initialize program finances
    (map-set program-finances
      { program-id: program-id }
      {
        total-revenue: u0,
        total-expenses: u0,
        equipment-costs: u0,
        coach-payments: u0,
        facility-costs: u0,
        profit-loss: 0
      }
    )

    ;; Increment program ID
    (var-set next-program-id (+ program-id u1))

    (ok program-id)
  )
)

;; Register for a program
(define-public (register-for-program (program-id uint) (participant-name (string-ascii 100)) (participant-age uint) (guardian-name (string-ascii 100)) (guardian-contact (string-ascii 100)) (emergency-contact (string-ascii 100)) (medical-info (string-ascii 200)))
  (let
    (
      (program (unwrap! (map-get? community-programs { program-id: program-id }) ERR-PROGRAM-NOT-FOUND))
      (registration-id (var-get next-registration-id))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (is-eq (get status program) "open") ERR-PROGRAM-NOT-FOUND)
    (asserts! (< (get current-participants program) (get max-participants program)) ERR-PROGRAM-FULL)
    (asserts! (and (>= participant-age (get age-min program)) (<= participant-age (get age-max program))) ERR-INVALID-AGE)

    ;; Create registration
    (map-set program-registrations
      { registration-id: registration-id }
      {
        program-id: program-id,
        participant-name: participant-name,
        participant-age: participant-age,
        guardian-name: guardian-name,
        guardian-contact: guardian-contact,
        emergency-contact: emergency-contact,
        medical-info: medical-info,
        registration-date: current-time,
        payment-status: "pending",
        amount-paid: u0,
        registered-by: tx-sender
      }
    )

    ;; Update program participant count
    (map-set community-programs
      { program-id: program-id }
      (merge program { current-participants: (+ (get current-participants program) u1) })
    )

    ;; Increment registration ID
    (var-set next-registration-id (+ registration-id u1))

    (ok registration-id)
  )
)

;; Process payment for registration
(define-public (process-payment (registration-id uint) (amount uint))
  (let
    (
      (registration (unwrap! (map-get? program-registrations { registration-id: registration-id }) ERR-REGISTRATION-NOT-FOUND))
      (program (unwrap! (map-get? community-programs { program-id: (get program-id registration) }) ERR-PROGRAM-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get registered-by registration)) ERR-NOT-AUTHORIZED)
    (asserts! (>= amount (get fee program)) ERR-PAYMENT-REQUIRED)

    ;; Update registration payment status
    (map-set program-registrations
      { registration-id: registration-id }
      (merge registration {
        payment-status: "paid",
        amount-paid: amount
      })
    )

    ;; Update program finances
    (let
      (
        (finances (unwrap-panic (map-get? program-finances { program-id: (get program-id registration) })))
      )
      (map-set program-finances
        { program-id: (get program-id registration) }
        (merge finances {
          total-revenue: (+ (get total-revenue finances) amount),
          profit-loss: (+ (get profit-loss finances) (to-int amount))
        })
      )
    )

    (ok true)
  )
)

;; Register as volunteer coach
(define-public (register-volunteer-coach (name (string-ascii 100)) (experience-years uint) (certifications (string-ascii 200)) (background-check bool) (availability (string-ascii 100)) (contact-info (string-ascii 100)))
  (begin
    (map-set volunteer-coaches
      { coach: tx-sender }
      {
        name: name,
        experience-years: experience-years,
        certifications: certifications,
        background-check: background-check,
        assigned-programs: (list),
        availability: availability,
        contact-info: contact-info
      }
    )
    (ok true)
  )
)

;; Assign coach to program
(define-public (assign-coach-to-program (coach principal) (program-id uint))
  (let
    (
      (coach-info (unwrap! (map-get? volunteer-coaches { coach: coach }) ERR-NOT-AUTHORIZED))
      (program (unwrap! (map-get? community-programs { program-id: program-id }) ERR-PROGRAM-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (get background-check coach-info) ERR-NOT-AUTHORIZED)

    ;; Add program to coach's assignments
    (map-set volunteer-coaches
      { coach: coach }
      (merge coach-info {
        assigned-programs: (unwrap-panic (as-max-len? (append (get assigned-programs coach-info) program-id) u5))
      })
    )

    (ok true)
  )
)

;; Record session attendance
(define-public (record-attendance (program-id uint) (session-date uint) (scheduled-participants uint) (actual-attendance uint) (session-notes (string-ascii 300)) (weather-cancelled bool))
  (let
    (
      (program (unwrap! (map-get? community-programs { program-id: program-id }) ERR-PROGRAM-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get coordinator program)) ERR-NOT-AUTHORIZED)

    (map-set program-attendance
      { program-id: program-id, session-date: session-date }
      {
        scheduled-participants: scheduled-participants,
        actual-attendance: actual-attendance,
        session-notes: session-notes,
        weather-cancelled: weather-cancelled,
        makeup-session-scheduled: false
      }
    )

    (ok true)
  )
)

;; Update program status
(define-public (update-program-status (program-id uint) (new-status (string-ascii 20)))
  (let
    (
      (program (unwrap! (map-get? community-programs { program-id: program-id }) ERR-PROGRAM-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set community-programs
      { program-id: program-id }
      (merge program { status: new-status })
    )

    (ok true)
  )
)

;; Read-only Functions

;; Get program details
(define-read-only (get-program (program-id uint))
  (map-get? community-programs { program-id: program-id })
)

;; Get registration details
(define-read-only (get-registration (registration-id uint))
  (map-get? program-registrations { registration-id: registration-id })
)

;; Get volunteer coach info
(define-read-only (get-volunteer-coach (coach principal))
  (map-get? volunteer-coaches { coach: coach })
)

;; Get program attendance
(define-read-only (get-program-attendance (program-id uint) (session-date uint))
  (map-get? program-attendance { program-id: program-id, session-date: session-date })
)

;; Get program finances
(define-read-only (get-program-finances (program-id uint))
  (map-get? program-finances { program-id: program-id })
)

;; Check program availability
(define-read-only (is-program-available (program-id uint))
  (let
    (
      (program (map-get? community-programs { program-id: program-id }))
    )
    (if (is-some program)
      (let
        (
          (program-data (unwrap-panic program))
        )
        (and
          (is-eq (get status program-data) "open")
          (< (get current-participants program-data) (get max-participants program-data))
        )
      )
      false
    )
  )
)

;; Get programs by type
(define-read-only (get-programs-by-type (program-type (string-ascii 30)))
  ;; In a real implementation, this would filter programs by type
  (ok program-type)
)
