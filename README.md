# EdiGateway: Electronic Data Interchange services for State-based Marketplaces

The EdiGateway is an enrollment database and integration service. It connects IdeaCrew's second generation internal SBM services with one another and integrates with commercial services like Oracle's B2B gateway to exchange enrollment transactions with trading partners.

The EdiGateway will replace the EDI Database (GlueDB). All EDI-related new development
will occur in the EdiGateway project. Toward this objective the ::UserFees code includes a feature that periodically polls the EDI Database for changed enrollment records, compares new with existing record states, interprets addition, termination and change kinds, and publishes corresponding events using EventSource.

## System Dependencies

### AcaEntities

Domain entities and contracts used in ::UserFees are defined primarily under ::AcaEntities::Ledger namespace

## Configuration

## Database

Like other IdeaCrew SBM solution services EdiGateway uses MongoDB as the primary database.

PostgreSql is installed for a narrow UserFees use case and is planned to be removed. Do not develop using ActiveRecord or PostgreSql without prior authorization from senior leadership.

- Database creation
- Database initialization

## Services

EdiGateway uses EventSource exclusively for event-based communication intra- and inter-service publish/subscribe messages over AMQP and HTTP protocols. Do not install or use deprecated tools, including Acapi and/or sneakers gems.

## Installing Dependencies

This applications depends on gems from private repositories. Before running `bundle` you must have a Personal Access Token (PAT) with `admin:org, repo` permissions. The PAT must be stored in the environment variable `BUNDLE_GITHUB__COM`.