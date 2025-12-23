# Research Generation Design

**Created**: 2025-12-22

**Goal**: Generate comprehensive company/role research to provide actionable insights for tailoring application materials (resume and cover letter).

## Purpose

The research document serves as the foundation for later phases:
- **Phase 4 (Resume)**: Uses research to identify which experiences to emphasize, technologies to highlight, and how to position skills
- **Phase 5 (Cover Letter)**: Uses research for company-specific personalization and cultural alignment
- **Phase 7 (Interview Prep)**: Can reference research for interview preparation content

## Architecture

### Components

**1. StatusLogger** (`lib/jojo/status_logger.rb`)
- Provides consistent logging across all generators
- Appends timestamped entries to `status_log.md`
- Supports metadata (tokens used, status, errors)
- Markdown formatting for readability

**2. ResearchGenerator** (`lib/jojo/generators/research_generator.rb`)
- Main orchestration class following existing JobDescriptionProcessor pattern
- Takes Employer instance, AIClient, and optional verbose flag
- Gathers inputs from multiple sources
- Performs web search (when available)
- Generates structured research using AI reasoning model
- Saves to `employers/#{slug}/research.md`

**3. Research Prompt** (`lib/jojo/prompts/research_prompt.rb`)
- Comprehensive prompt template requesting structured analysis
- Adapts based on available inputs
- Instructs AI to read between the lines and infer implicit information

### Data Flow

```
1. Input Gathering
   ├─ Read job_description.md (required)
   ├─ Read job_details.yml to extract company name
   ├─ Read inputs/generic_resume.md (optional)
   └─ Perform web search for company (optional)

2. Prompt Construction
   └─ Combine all inputs into comprehensive research prompt

3. AI Analysis
   └─ Use reasoning model (Sonnet) for deep inference

4. Output
   ├─ Save research.md with structured sections
   └─ Log to status_log.md with metadata
```

## Research Output Structure

The generated `research.md` contains four main sections:

### 1. Company Profile (~200-300 words)
- Mission, values, and culture (from web search + job description language)
- Recent news, achievements, or changes
- Products/services overview
- Tech stack and engineering practices (if discoverable)

### 2. Role Analysis (~200-300 words)
- Core responsibilities breakdown
- Required vs. nice-to-have skills categorized
- What success looks like in this role (inferred from job description)
- Team context and reporting structure (if mentioned)

### 3. Strategic Positioning (~300-400 words)
When generic resume is available:
- Gap analysis: What they need vs. what the seeker offers
- Top 3-5 selling points to emphasize
- Technologies/experiences from resume that align with requirements
- Potential concerns to address or reframe

When resume is not available:
- Most critical requirements for the role
- Technologies and skills to emphasize
- Experience level expectations
- General recommendations for strong candidates

### 4. Tailoring Recommendations (~200 words)
- Specific keywords and phrases to incorporate
- Cultural language to mirror
- Projects/experiences to highlight (if resume available)
- Tone/voice suggestions based on company culture

## Input Sources

### Required Inputs
- **Job Description** (`employers/#{slug}/job_description.md`): Core information about the role and company
- **Job Details** (`employers/#{slug}/job_details.yml`): Extracted company name and structured data

### Optional Inputs
- **Generic Resume** (`inputs/generic_resume.md`): Enables personalized gap analysis and strategic positioning
- **Web Search Results**: Provides current company context beyond job description

### Graceful Degradation

The system continues to function with reduced capability when optional inputs are unavailable:

| Missing Input | Impact | Behavior |
|--------------|---------|----------|
| Web search fails | Less current company info | Uses job description language to infer company culture |
| Generic resume missing | No personalized positioning | Provides generic recommendations instead of personalized gap analysis |
| Job description missing | Cannot proceed | Raises error and exits |

## Error Handling

- **Job description not found**: Raise error (cannot proceed without core requirement)
- **Web search fails**: Log warning, continue with job description analysis only
- **Generic resume missing**: Log warning, generate research without Strategic Positioning section
- **AI call fails**: Propagate error to CLI for user-friendly message and status logging

## Testing Strategy

### Unit Tests
- **StatusLogger**: Test log creation, appending, formatting, metadata
- **Research Prompt**: Test prompt generation with various input combinations
- **ResearchGenerator**: Mock all external dependencies (AI, web search, file reads)

### Mocking Strategy
- Use `Minitest::Mock` for AIClient
- Stub `perform_web_search` method for web search results
- Create fixtures for job descriptions, resumes, and job details
- No tests should call actual third-party APIs

### Integration Testing
- Manual testing with real API key for end-to-end validation
- Verify research.md structure and content quality
- Verify status_log.md entries

## Web Search Integration

**Challenge**: WebSearch is a Claude Code tool, not available in standalone Ruby execution.

**Solution**: Document that web search requires Claude Code environment:
- `perform_web_search` method returns nil in standalone mode
- When Claude Code executes the generator, it can replace the method invocation with actual WebSearch tool usage
- System gracefully degrades to job-description-only analysis when web search unavailable

**Future Enhancement**: Could add optional integration with external search APIs (Google Custom Search, Bing) for standalone execution.

## CLI Integration

### New Command: `research`
```bash
./bin/jojo research -e "Company Name" -j job_description.txt
```

Runs research generation only. Requires job description to already be processed.

### Updated Command: `generate`
```bash
./bin/jojo generate -e "Company Name" -j job_description.txt
```

Workflow updated to:
1. Process job description (Phase 2)
2. **Generate research (Phase 3)** ← NEW
3. Generate resume (Phase 4 - coming)
4. Generate cover letter (Phase 5 - coming)
5. Generate website (Phase 6 - coming)
6. Generate PDFs (Phase 7 - coming)

## Dependencies for Later Phases

**Phase 4 (Resume Generation)** will:
- Read `research.md` to understand which experiences to emphasize
- Use Strategic Positioning section for gap analysis
- Incorporate Tailoring Recommendations keywords and cultural language

**Phase 5 (Cover Letter)** will:
- Use Company Profile for personalization
- Reference Role Analysis for addressing requirements
- Apply Tailoring Recommendations tone/voice suggestions

**Phase 7 (Interview Prep)** can:
- Build on research content for interview questions
- Expand Company Profile for "why this company" answers
- Use Role Analysis for "why this role" preparation

## Design Decisions

### Why reasoning model (Sonnet) instead of text generation (Haiku)?
Research requires deep inference, reading between the lines, and strategic analysis. The reasoning model provides higher quality insights worth the additional token cost.

### Why combine all inputs in a single prompt?
Allows the AI to make connections across inputs (e.g., "They need X, you have similar experience with Y, emphasize Z aspect"). Separate prompts would miss these insights.

### Why graceful degradation instead of failing?
Better user experience - system provides value even when some inputs unavailable. Job seeker may not have resume ready yet, or web search may be unavailable.

### Why separate StatusLogger class?
- Consistent logging format across all generators
- Single source of truth for status log entries
- Easy to extend with additional metadata
- CLI can use it without duplicating logic

## Future Enhancements

- Add support for external search API integration (Google Custom Search)
- Allow user to provide additional context files (e.g., `inputs/company_notes.md`)
- Generate multiple research variants with different focus areas
- Add scoring/confidence levels for gap analysis
- Support incremental updates (re-run research with new inputs)
