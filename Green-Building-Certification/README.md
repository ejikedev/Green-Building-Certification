# Green Building Certification Smart Contract

## Overview

The Green Building Certification smart contract is a blockchain-based solution for verifying and managing sustainable construction practices on the Stacks blockchain. This contract enables transparent, immutable certification of green buildings with comprehensive scoring systems and document verification.

## Features

- **Building Registration**: Register buildings for green certification assessment
- **Authorized Verifiers**: Certified professionals can assess and verify building sustainability
- **Comprehensive Scoring**: Multi-criteria assessment including energy efficiency, water conservation, materials, and air quality
- **Certification Levels**: Bronze, Silver, Gold, and Platinum certifications based on scores
- **Document Management**: Upload and verify construction documents with hash verification
- **Certification Renewal**: Periodic renewal system with expiry tracking
- **Transparency**: All certifications are publicly verifiable on the blockchain

## Certification Criteria

### Scoring System (Total: 100 points)
- **Energy Efficiency**: 25 points maximum
- **Water Conservation**: 25 points maximum  
- **Material Sustainability**: 25 points maximum
- **Indoor Air Quality**: 20 points maximum
- **Innovation Points**: 5 points maximum

### Certification Levels
- **Bronze**: 70-79 points
- **Silver**: 80-89 points
- **Gold**: 90-94 points
- **Platinum**: 95+ points

## Contract Functions

### Public Functions

#### Building Management
- `register-building(name, location, construction-date)` - Register a new building
- `submit-assessment(building-id, scores...)` - Submit sustainability assessment scores
- `issue-certification(building-id)` - Issue certification after assessment
- `renew-certification(building-id, new-score)` - Renew existing certification

#### Document Management
- `upload-document(building-id, doc-type, doc-hash)` - Upload document hash
- `verify-document(building-id, doc-type)` - Verify uploaded document

#### Verifier Management
- `add-verifier(verifier, name, license-number)` - Add authorized verifier (owner only)

### Read-Only Functions
- `get-building-info(building-id)` - Get complete building information
- `get-verifier-info(verifier)` - Get verifier details
- `is-certification-valid(building-id)` - Check if certification is still valid
- `get-total-certified-buildings()` - Get total number of certified buildings

## Usage Examples

### 1. Register a Building
```clarity
(contract-call? .green-building-cert register-building 
  "Green Tower Complex" 
  "123 Sustainable St, EcoCity" 
  u2023001)
```

### 2. Add Authorized Verifier
```clarity
(contract-call? .green-building-cert add-verifier 
  'SP1HJKAJSD... 
  "EcoCert Solutions" 
  "GBC-2024-001")
```

### 3. Submit Assessment
```clarity
(contract-call? .green-building-cert submit-assessment 
  u1      ;; building-id
  u23     ;; energy-efficiency
  u22     ;; water-conservation  
  u24     ;; material-sustainability
  u18     ;; indoor-air-quality
  u4)     ;; innovation-points
```

### 4. Issue Certification
```clarity
(contract-call? .green-building-cert issue-certification u1)
```

## Deployment Instructions

### Prerequisites
- Stacks CLI installed
- Testnet/Mainnet STX for deployment
- Clarinet for local testing (optional)

### Deploy to Testnet
```bash
stx deploy_contract green-building-cert green-building-cert.clar --testnet
```

### Deploy to Mainnet
```bash
stx deploy_contract green-building-cert green-building-cert.clar --mainnet
```

## Testing

### Unit Tests
Run comprehensive tests using Clarinet:

```bash
clarinet test
```

### Integration Tests
Test contract interactions:

```bash
clarinet console
```

## Security Considerations

- Only contract owner can add verifiers
- Verifiers can only assess buildings assigned to them
- Certifications have expiry dates for periodic renewal
- Document hashes ensure data integrity
- All actions are immutable and auditable

## Error Codes

| Code | Description |
|------|-------------|
| 100  | Unauthorized access |
| 101  | Building/record not found |
| 102  | Record already exists |
| 103  | Invalid score submitted |
| 104  | Invalid status transition |
| 105  | Certification expired |
| 106  | Insufficient score for certification |

## Contract Constants

- **Minimum Certification Score**: 70 points
- **Certificate Validity**: ~1 year (144,000 blocks)
- **Maximum Assessment Score**: 100 points

## Future Enhancements

- Integration with IoT sensors for real-time monitoring
- Carbon credit tracking and trading
- Multi-language support for international use
- Mobile app integration
- Automated renewal notifications

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Support

For support and questions:
- Create an issue in the GitHub repository
- Contact the development team
- Check the documentation wiki

## Changelog

### Version 1.0.0
- Initial release with core certification functionality
- Multi-criteria scoring system
- Document verification system
- Verifier authorization system
- Certification renewal capability