FROM postgres:16-alpine

# Copy seed scripts
COPY seed-data.sql /seed/seed-data.sql
COPY run-seed.sh /seed/run-seed.sh

# Make script executable
RUN chmod +x /seed/run-seed.sh

# Set working directory
WORKDIR /seed

# Run the seed script
ENTRYPOINT ["/seed/run-seed.sh"]
