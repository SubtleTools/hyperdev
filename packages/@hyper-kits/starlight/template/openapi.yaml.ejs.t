---
to: <%= projectFolder %>/openapi.yaml
skip: <%= !enableOpenAPI %>
---
openapi: 3.0.0
info:
  title: <%= projectName %> API
  description: <%= projectDescription %>
  version: 1.0.0
servers:
  - url: <%= siteUrl ? siteUrl + '/api' : 'http://localhost:3000/api' %>
    description: Development server
paths:
  /health:
    get:
      summary: Health check endpoint
      responses:
        '200':
          description: Service is healthy
          content:
            application/json:
              schema:
                type: object
                properties:
                  status:
                    type: string
                    example: "ok"
                  timestamp:
                    type: string
                    format: date-time
components:
  schemas:
    Error:
      type: object
      required:
        - code
        - message
      properties:
        code:
          type: integer
          format: int32
        message:
          type: string