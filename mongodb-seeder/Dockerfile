FROM mongo:6

# Copy the seed script
COPY seed-mongodb.sh /seed-mongodb.sh
RUN chmod +x /seed-mongodb.sh

ENTRYPOINT ["/seed-mongodb.sh"]
