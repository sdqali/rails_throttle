class RateLimit
  def initialize(app)
    @app = app
  end

  def call(env)
    client_ip = env["REMOTE_ADDR"]
    key = "count:#{client_ip}"
    count = REDIS.get(key)
    unless count
      REDIS.set(key, 0)
      REDIS.expire(key, THROTTLE_TIME_WINDOW)
    end

    if count.to_i >= THROTTLE_MAX_REQUESTS
      [
       429,
       rate_limit_headers(count, key),
       [message]
      ]
    else
      REDIS.incr(key)
      status, headers, body = @app.call(env)
      [
       status,
       headers.merge(rate_limit_headers(count.to_i + 1, key)),
       body
      ]
    end
  end

  private
  def message
    {
      :message => "You have fired too many requests. Please wait for some time."
    }.to_json
  end

  def rate_limit_headers(count, key)
    ttl = REDIS.ttl(key)
    time = Time.now.to_i
    time_till_reset = (time + ttl.to_i).to_s
    {
      "X-Rate-Limit-Limit" =>  "60",
      "X-Rate-Limit-Remaining" => (60 - count.to_i).to_s,
      "X-Rate-Limit-Reset" => time_till_reset
    }
  end
end
