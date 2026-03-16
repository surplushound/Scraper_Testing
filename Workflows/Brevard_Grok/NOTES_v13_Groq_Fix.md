# Brevard Scraper v13 - Groq Fix Notes

## Problem
HTTP POST to Brevard works, but Groq fails with:
- "failed to unmarshal JSON: unexpected end of JSON input"
- Issue: bodyParameters expression `{{ $json.message }}` not being properly evaluated/serialized

## Root Cause
In n8n's HTTP Request node, using `bodyParameters` with expressions for complex objects (like the `messages` array) fails because n8n doesn't properly serialize the expression result.

## Solutions Tried

### Attempt 1 (Failed)
- Added "Build Groq Body" Code node to pre-build full JSON
- Used `bodyContent: "={{ $json.body }}"` with pre-stringified body
- **Result:** n8n double-encoded the JSON (stringified an already-stringified string)

### Attempt 2 (Failed)
- Had Code node return raw object with `model` and `messages` properties
- Used `bodyParameters` with expressions `={{ $json.model }}` and `={{ $json.messages }}`
- **Result:** Expressions still not properly serializing the messages array

### Attempt 3 (Current - Should Work)
- Code node passes just the `message` string
- Use `JSON.stringify()` inside the expression itself:
  ```
  bodyParameters: {
    "model": "llama-3.1-70b-versatile",
    "messages": "={{ JSON.stringify([{role: 'user', content: $json.message}]) }}"
  }
  ```
- **Result:** The JSON.stringify() runs at runtime, properly serializing the array

## API Key Issue
- Current key 
- Likely issue was the JSON format, not the key itself

## Excel Path Issue
- Known n8n limitation: file paths in ReadWriteFile nodes don't survive JSON import
- After importing v13, manually re-select the Excel file path

## v13 Workflow Structure
1. Manual Trigger
2. HTTP POST (Direct) → Brevard realTDM
3. Prepare Prompt → Extract HTML to prompt
4. Build Groq Body → Pass message to next node
5. Groq → HTTP Request with JSON.stringify() in expression
6. Parse → Extract JSON from Groq response
7. Check → If no cases, stop; if cases, continue
8. Read Excel → Read existing data
9. Combine → Merge new + existing
10. Write Excel → Save results
