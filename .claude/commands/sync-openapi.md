Use OpenAPI MCP, make sure all Dtos from OpenAPI are synced with the code.
Sync all API requests with frontend. Make sure all API requests meet API schemes.
Do not create script for syncing Dtos, just use OpenAPI MCP.
Request and Response DTOs names must match to OpenAPI names.
Use x-roles-required for identifying roles required for each endpoint.
Use x-query-dto and x-query-dto-schema for identifying query DTOs and their schemas.
If you see any errors or mismatches, fix them. If you see any missing DTOs or endpoints, create them.

Add proper dartdoc comments for each endpoint which includes:
- Description of the endpoint
- Roles required for the endpoint

Example:
```dart
/// Get all messages for the current user.
/// Roles required: APPLICANT, COMPANY_OWNER, RECRUITER
@GET(_Paths.messages)
Future<ListResponseDto<MessageDto>> _getMessages({
  @Queries() required MessagePageOptionsDto pageOptions,
});
```
