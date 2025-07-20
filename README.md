# Smart Public Basketball Court Management System

A comprehensive blockchain-based system for managing public basketball courts using Clarity smart contracts on the Stacks blockchain.

## System Overview

This system consists of five interconnected smart contracts that manage different aspects of a public basketball court:

### 1. Court Scheduling Contract (`court-scheduling.clar`)
- Manages league games and tournament bookings
- Handles time slot reservations
- Tracks court availability
- Manages booking conflicts and priorities

### 2. Lighting Control Contract (`lighting-control.clar`)
- Operates court illumination for evening play
- Manages automated lighting schedules
- Tracks energy usage and costs
- Handles manual override controls

### 3. Equipment Maintenance Contract (`equipment-maintenance.clar`)
- Coordinates hoop repairs and court cleaning
- Schedules regular maintenance tasks
- Tracks equipment condition and replacement needs
- Manages maintenance crew assignments

### 4. Safety Monitoring Contract (`safety-monitoring.clar`)
- Tracks injuries and incidents
- Maintains first aid supply inventory
- Manages emergency contact information
- Records safety inspection reports

### 5. Community Program Contract (`community-program.clar`)
- Organizes youth basketball leagues and clinics
- Manages program registration and fees
- Tracks participant information
- Coordinates volunteer coaches and staff

## Features

### Court Scheduling
- Time-based booking system with hourly slots
- Priority booking for leagues and tournaments
- Conflict resolution and waitlist management
- Automated booking confirmations

### Smart Lighting
- Automated on/off based on bookings
- Manual override capabilities
- Energy usage tracking
- Maintenance scheduling for lighting equipment

### Equipment Management
- Regular inspection scheduling
- Repair request tracking
- Equipment replacement planning
- Maintenance cost tracking

### Safety & Compliance
- Incident reporting system
- First aid supply management
- Safety equipment inspection logs
- Emergency response procedures

### Community Programs
- Youth league registration
- Clinic and camp management
- Volunteer coordination
- Program fee collection

## Data Structures

### Court Booking
- Booking ID
- Date and time slot
- Booking type (league, tournament, casual)
- Contact information
- Status (confirmed, pending, cancelled)

### Lighting Schedule
- Schedule ID
- Start/end times
- Automation rules
- Manual overrides
- Energy consumption data

### Maintenance Task
- Task ID
- Equipment type
- Priority level
- Assigned crew
- Completion status

### Safety Record
- Incident ID
- Date and time
- Incident type
- Severity level
- Response actions

### Program Registration
- Registration ID
- Participant information
- Program type
- Payment status
- Emergency contacts

## Installation

1. Install Clarinet CLI
2. Clone this repository
3. Run `clarinet check` to validate contracts
4. Run `npm test` to execute test suite

## Testing

The system includes comprehensive tests using Vitest:

\`\`\`bash
npm install
npm test
\`\`\`

## Deployment

Deploy contracts to Stacks testnet or mainnet using Clarinet:

\`\`\`bash
clarinet deploy --testnet
\`\`\`

## Usage

Each contract can be interacted with independently or as part of the integrated system. Refer to individual contract documentation for specific function calls and parameters.

## Security Considerations

- All contracts include proper access controls
- Input validation on all public functions
- Error handling for edge cases
- Audit trail for all transactions

## Contributing

Please read the PR-DETAILS.md file for contribution guidelines and development workflow.

(define-private (get-hour-availability-for-court (key { court-number: uint, date: uint, hour: uint }))
  (default-to { available: true, booking-id: none } (map-get? court-availability key))
)
