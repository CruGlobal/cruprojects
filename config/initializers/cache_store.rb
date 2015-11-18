# Be sure to restart your server when you modify this file.
require Rails.root.join('config', 'initializers', 'redis')

Rails.application.config.cache_store = :redis_store, {
  host: Redis.current.client.host,
  port: Redis.current.client.port,
  db: 1,
  namespace: "cruprojects:cache:",
  expires_in: 1.day
}
