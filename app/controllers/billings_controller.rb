class BillingsController < ApplicationController
  before_action :authenticate_user!
  def index
    @billings = current_user.billings
  end


  def pre_pay
    orders = current_user.orders.cart
    total = orders.get_total
    items = get_items_hash(orders)

    # Build Payment object
    @payment = PayPal::SDK::REST::Payment.new({
      :intent =>  "sale",
      :payer =>  {
        :payment_method =>  "paypal" },
      :redirect_urls => {
        :return_url => execute_billings_url,
        :cancel_url => "http://localhost:3000/" },
      :transactions =>  [{
        :item_list => {
          :items => items 
        },
        :amount =>  {
          :total =>  total,
          :currency =>  "USD" },
        :description =>  "Carro de compra" }]})
    if @payment.create
      #render json: @payment.to_json
      redirect_url = @payment.links.find{ |v| v.method == "REDIRECT" }.href
      redirect_to redirect_url
    else
      ':('
    end
  end

  def execute
    #render json: params
    payment = PayPal::SDK::REST::Payment.find(params[:paymentId])

    if payment.execute( :payer_id => params[:PayerID] )
      amount = payment.transactions.first.amount.total

      billing = Billing.create(
        user: current_user,
        code: payment.id,
        payment_method: 'paypal',
        amount: amount,
        currency: 'USD'
        )
      orders = current_user.orders.cart
      orders.update_all(payed: true, billing_id: billing.id)

      redirect_to root_path, notice: "La compra se realizó con exito"
      # Success Message
      # Note that you'll need to `Payment.find` the payment again to access user info like shipping address
      #render plain: ":)"
    else
      render plain: "No se pudo realizar el cobro"
      #payment.error # Error Hash
    end
  end

  private
  def get_items_hash(orders)
    items = orders.map do |order|
      item = {}
      item[:name] = order.product.name
      item[:sku] = order.id.to_s
      item[:price] = order.price.to_s
      item[:currency] = 'USD'
      item[:quantity] = order.quantity
      item
    end
  end

end
