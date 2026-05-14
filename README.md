Code Challenge for Senior Ruby Software Engineer
Problem Statement

"Live Coding Challenge: Book Management System Enhancements
Overview

This live coding challenge evaluates your ability to design, implement, and optimize backend functionality for a book management system. The goal is to assess your coding proficiency, problem-solving skills, and understanding of performance optimization while adhering to best practices.

Instructions


Time Limit: You will have 30 minutes to complete as much of the challenge as possible.
Tools: You may use the tools provided in the coding environment, including access to a Rails application skeleton. If needed, discuss any assumptions with the interviewer.
Testing: Include test cases where appropriate to validate your implementation.

Challenge Tasks

1. Book Reservations

Objective: Implement a feature for reserving books.

- Create a new endpoint: POST /books/:id/reserve
- The reservation should contains the email of the user that did the reservation
- The status of the book should be changed to :reserved
- Consider potential edge cases (e.g., what happens when a user tries to reserve a book that is already checked out or reserved?).
- Write unit tests for checking the reservation endpoint

2. Optimize GET endpoints

Objective: Optimize the existing GET API endpoints for fetching details.

Evaluation Criteria

Code Quality: Clean, maintainable, and adheres to best practices.
Problem-Solving: Ability to address edge cases, optimize queries, and handle errors effectively.
Performance: Queries and endpoints should handle large datasets without degradation.
Communication: Clear explanation of decisions, trade-offs, and potential improvements.
Testing: Coverage of key functionality with robust test cases."
