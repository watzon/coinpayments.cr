require "uri"
require "json"
require "http/client"
require "openssl/hmac"

module CoinPayments
  class Client
    property public_key : String

    property private_key : String

    property user_agent : String

    private getter client : HTTP::Client

    def initialize(@public_key,
                   @private_key,
                   user_agent = nil,
                   client = nil,
                   endpoint = API_ENDPOINT)
      @client = client || HTTP::Client.new(URI.parse(endpoint))
      @user_agent = user_agent ? user_agent : USER_AGENT
    end

    def request(type : U.class, command, params = {} of String => String) forall U
      res = request(command, params)
      type.from_json(res)
    end

    def request(command, params = {} of String => String)
      params = params.to_h
        .transform_keys(&.to_s)
        .transform_values do |val|
          case val
          when Bool
            val ? "1" : "0"
          else
            val
          end
        end

      params["cmd"] ||= command.to_s
      params["key"] ||= @public_key
      params["version"] ||= API_VERSION
      params["format"]  ||= API_FORMAT

      params = HTTP::Params.encode(params)
      form = params.to_s

      headers = HTTP::Headers{
        "User-Agent" => @user_agent,
        "HMAC" => generate_hmac(form)
      }

      response = @client.post(API_PATH, headers: headers, form: form)
      json = JSON.parse(response.body)
      if json["error"].as_s == API_VALID_RESPONSE
        result = json["result"].to_json
        result = "{}" if result == "[]"
        result
      else
        raise Error.new(json["error"].as_s)
      end
    end

    # Get basic account information
    def basic_account_info
      request(GetBasicInfoResponse, :get_basic_info)
    end

    def rates(short = false, accepted = false)
      request(RatesResponse, :rates, {short: short, accepted: accepted})
    end

    def create_transaction(amount,
                           currency1,
                           currency2 = currency1,
                           buyer_email = nil,
                           address = nil,
                           buyer_name = nil,
                           item_name = nil,
                           item_number = nil,
                           invoice = nil,
                           custom = nil,
                           ipn_url = nil,
                           success_url = nil,
                           cancel_url = nil)
      request(CreateTransactionResponse, :create_transaction, {
        amount: amount,
        currency1: currency1,
        currency2: currency2,
        buyer_email: buyer_email,
        address: address,
        buyer_name: buyer_name,
        item_name: item_name,
        item_number: item_number,
        invoice: invoice,
        custom: custom,
        ipn_url: ipn_url,
        success_url: success_url,
        cancel_url: cancel_url
      })
    end

    def get_callback_address(currency, ipn_url = nil, label = nil)
      request(GetCallbackAddressResponse, :get_callback_address, {
        currency: currency,
        ipn_url: ipn_url,
        label: label
      })
    end

    def tx_info(txid : String, full = false)
      request(GetTxResponse, :get_tx_info, {
        txid: txid,
        full: full
      })
    end

    def tx_info(txids : Array(String))
      request(GetTxListResponse, :get_tx_info_multi)
    end

    def tx_ids(limit = false, start = 0, newer = false, all = false)
      request(Array(String), :get_tx_ids, {
        limit: limit,
        start: start,
        newer: newer,
        all: all
      })
    end

    def balances(all = false)
      request(BalanceResponse, :balances, {all: all})
    end

    def deposit_address(currency)
      request(GetDepositAddressResponse, :get_deposit_address, {currency: currency})
    end

    def create_transfer(amount,
                        currency,
                        merchant = nil,
                        pbntag = nil,
                        auto_confirm = false,
                        note = nil)
      raise Error.new("Either a merchant id or a pay by name tag is required") unless merchant || pbntag
      request(CreateTransferResponse, :creatr_transfer, {
        amount: amount,
        currency: currency,
        merchant: merchant,
        pbntag: pbntag,
        auto_confirm: auto_confirm,
        note: note
      })
    end

    def create_withdrawal(amount,
                          currency,
                          add_tx_fee = false,
                          currency2 = currency,
                          address = nil,
                          pbntag = nil,
                          dest_tag = nil,
                          ipn_url = nil,
                          auto_confirm = false,
                          note = nil)
      raise Error.new("Either an address or a pay by name tag is required") unless address || pbntag
      request(CreateWithdrawalResponse, :create_withdrawal, {
        amount: amount,
        currency: currency,
        add_tx_fee: add_tx_fee,
        currency2: currency2,
        address: address,
        pbntag: pbntag,
        dest_tag: dest_tag,
        ipn_url: ipn_url,
        auto_confirm: auto_confirm,
        note: note
      })
    end

    # TODO: create_mass_withdrawal

    def convert_coins(amount,
                      from,
                      to,
                      address = nil,
                      dest_tag = nil)
      request(ConvertCoinsResponse, :convert, {
        amount: amount,
        from: from,
        to: to,
        address: address,
        dest_tag: dest_tag
      })
    end

    def conversion_limits(from, to)
      request(ConvertLimitsResponse, :convert_limits, {from: from, to: to})
    end

    def withdrawal_history(limit = 25, start = 0, newer = false)
      request(GetWithdrawalHistoryResponse, :get_withdrawal_history, {
        limit: limit,
        start: start,
        newer: newer
      })
    end

    def withdrawal_info(id)
      request(GetWithdrawalInfoResponse, :get_withdrawal_info, {id: id})
    end

    def conversion_info(id)
      request(ConversionInfoResponse, :get_conversion_info, {id: id})
    end

    def profile_info(pbntag)
      request(GetProfileResponse, :get_pbn_info, {pbntag: pbntag})
    end

    def tag_list
      request(TagListResponseSingle, :get_pbn_list)
    end

    def buy_tags(coin, num)
      request(Hash(String, String), :buy_pbn_tags)
    end

    def claim_tag(tagid, name)
      request(Hash(String, String), claim_pbn_tag, {tagid: tagid, name: name})
    end

    def update_tag(tagid,
                   name = nil,
                   email = nil,
                   url = nil,
                   image = nil)
      request(Hash(String, String), :update_pbn_tag, {
        tagid: tagid,
        name: name,
        email: email,
        url: url,
        image: image
      })
    end

    def renew_tag(tagid, coin, years = 1)
      request(Hash(String, String), :renew_pbn_tag, {
        tagid: tagid,
        coin: coin,
        years: years
      })
    end

    def delete_tag(tagid)
      request(Hash(String, String), :delete_pbn_tag, {tagid: tagid})
    end

    def claim_coupon(coupon)
      request(ClaimCouponResponse, :claim_pbn_coupon, {coupon: coupon})
    end

    private def generate_hmac(params)
      OpenSSL::HMAC.hexdigest(:sha512, private_key, params)
    end
  end
end
