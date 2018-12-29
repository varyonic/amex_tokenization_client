class AmexTokenizationClient
  class NotificationsPayload
    attr_reader :token_ref_id, :notification_type

    def initialize(token_ref_id:, notification_type:)
      @token_ref_id, @notification_type = token_ref_id, notification_type
    end

    def to_json(_encryption_key_id, _encryption_key)
      Hash[
        token_ref_id: token_ref_id,
        notification_type: notification_type
      ].to_json
    end
  end
end
