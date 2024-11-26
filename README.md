# Project Documentation
This project implements an ACL-based access control system for a PostgreSQL database.
## Project Structure
- **triggers/**: Contains SQL scripts for triggers related to ACL updates and hierarchy management.
- **functions/**: Contains stored procedures and functions for ACL checking, merging, and hierarchy handling.
- **tables/**: Defines core tables like `t_artist`, `t_creation`, and `t_group`.
- **tests/**: Scripts to validate performance and correctness of ACL operations.
## Setup
1. Run the scripts in `tables/` to create the core schema.
2. Execute the scripts in `functions/` to add ACL logic and utility functions.
3. Apply the triggers from `triggers/` to enable dynamic updates.
4. Use scripts in `tests/` to evaluate the system's function and performance.
