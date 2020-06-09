module CoinPayments
  struct GetBasicInfoResponse
    include JSON::Serializable

    getter uername : String

    getter username : String

    getter merchant_id : String

    getter email : String

    getter public_name : String

    @[JSON::Field(converter: Time::EpochConverter)]
    getter time_joined : Time

    getter kyc_status : Bool

    getter swych_tos_accepted : Bool
  end

  struct GetProfileResponse
    include JSON::Serializable

    getter pbntag : String

    getter merchant : String

    getter profile_name : String

    getter profile_url : String

    getter profile_email : String

    getter profile_image : String

    @[JSON::Field(converter: Time::EpochConverter)]
    getter member_since : Time

    getter feedback : Feedback

    struct Feedback
      include JSON::Serializable

      getter pos : Int32

      getter neg : Int32

      getter neut : Int32

      getter total : Int32

      getter percent : String

      getter percent_str : String
    end
  end

  struct TagListResponseSingle
    include JSON::Serializable

    getter tagid : String

    getter pbntag : String

    @[JSON::Field(converter: Time::EpochConverter)]
    getter time_expires : Int32
  end

  struct GetDepositAddressResponse
    include JSON::Serializable

    getter address : String

    getter pubkey : String?

    getter dest_tag : Int32?
  end

  struct GetCallbackAddressResponse
    include JSON::Serializable

    getter address : String
  end

  alias RatesResponse = Hash(String, Rate)

  struct Rate
    include JSON::Serializable

    @[JSON::Field(converter: CoinPayments::BoolToIntConverter)]
    getter is_fiat : Bool

    getter rate_btc : String

    getter last_update : String

    getter tx_fee : String

    getter status : String

    getter name : String

    getter confirms : String

    @[JSON::Field(converter: CoinPayments::BoolToIntConverter)]
    getter can_convert : Bool

    getter capabilities : Array(String)

    getter explorer : String?
  end

  alias BalanceResponse = Hash(String, Balance)

  struct Balance
    include JSON::Serializable

    # Balance in satoshi
    getter balance : Int32

    # Floating point balance
    getter balancef : Float64

    getter status : String

    getter coin_status : String
  end

  struct CreateTransactionResponse
    include JSON::Serializable

    getter amount : String

    getter txn_id : String

    getter address : String

    getter confirms_needed : String

    getter timeout : Int32

    getter status_url : String

    getter qrcode_url : String
  end

  struct GetTxResponse
    include JSON::Serializable

    @[JSON::Field(converter: Time::EpochConverter)]
    getter time_created : Time

    @[JSON::Field(converter: Time::EpochConverter)]
    getter time_expires : Time

    getter status : Int32

    getter status_text : String

    getter type : String

    getter coin : String

    getter amount : Int32

    getter amountf : String

    getter received : Int32

    getter receivedf : Float64

    getter recv_confirms : Int32

    getter payment_address : String
  end

  alias GetTxListResponse = Hash(String, TxListItem)

  struct TxListItem
    include JSON::Serializable

    getter error : String

    getter amount : String

    getter txn_id : String

    getter address : String

    getter confirms_needed : String

    getter timeout : Int32

    getter status_url : String

    getter qrcode_url : String
  end

  struct ConvertLimitsResponse
    include JSON::Serializable

    getter min : String

    getter max : String

    getter shapeshift_linked : Bool
  end

  struct ConvertCoinsResponse
    include JSON::Serializable

    getter id : String
  end

  struct ConversionInfoResponse
    include JSON::Serializable

    @[JSON::Field(converter: Time::EpochConverter)]
    getter time_created : Time

    getter status : Int32

    getter status_text : String

    getter coin1 : String

    getter coin2 : String

    getter amount_sent : Int32

    getter amount_sentf : Float64

    getter received : Int32

    getter receivedf : Float64
  end

  struct CreateTransferResponse
    include JSON::Serializable

    getter id : String

    getter status : Int32
  end

  struct CreateWithdrawalResponse
    include JSON::Serializable

    getter id : String

    getter amount : Int32

    getter status : Int32

    getter error : String?
  end

  alias CreateMassWithdrawalResponse = Hash(String, CreateWithdrawalResponse)

  struct GetWithdrawalInfoResponse
    include JSON::Serializable

    @[JSON::Field(converter: Time::EpochConverter)]
    getter time_created : Time

    getter status : Int32

    getter status_text : String

    getter coin : String

    getter amount : Int32

    getter amountf : Float64

    getter send_address : String

    getter send_txid : String
  end

  alias GetWithdrawalHistoryResponse = Array(GetWithdrawalHistoryResponseSingle)

  struct GetWithdrawalHistoryResponseSingle
    include JSON::Serializable

    getter id : String

    @[JSON::Field(converter: Time::EpochConverter)]
    getter time_created : Time

    getter status : Int32

    getter status_text : String

    getter coin : String

    getter amount : Int32

    getter amountf : Float64

    getter send_address : String

    getter send_txid : String
  end

  struct ClaimCouponResponse
    include JSON::Serializable

    getter tagid : String
  end

  module BoolToIntConverter
    def self.to_json(value : Bool, json : JSON::Builder)
      json.number(value ? 1 : 0)
    end

    def self.from_json(pull : JSON::PullParser)
      pull.read_int == 1
    end
  end
end
