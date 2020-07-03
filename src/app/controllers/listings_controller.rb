class ListingsController < ApplicationController
  before_action :set_listing, only: [:show]
  before_action :set_user_listing, only: [:edit, :update, :destroy]
  before_action :set_category, only: [:new, :edit]
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]

  # GET /listings
  # GET /listings.json
  def index
      @q = Listing.ransack(params[:q])
      @listings = @q.result.includes(category: [])
      @totallistings = Listing.all
      @totallistings.sort_by(&:created_at)
      
     
  end

  # GET /listings/1
  # GET /listings/1.json
  def show

    if current_user #user_signed_in?
    session = Stripe::Checkout::Session.create(
        payment_method_types: ['card'],
        customer_email: current_user.email,
        line_items: [{
            name: @listing.title,
            description: @listing.description,
            amount: @listing.deposit * 100,
            currency: 'aud',
            quantity: 1,
        }],
        payment_intent_data: {
            metadata: {
                user_id: current_user.id,
                listing_id: @listing.id
            }
        },
        success_url: "#{root_url}payments/success?userId=#{current_user.id}&listingId=#{@listing.id}",
        cancel_url: "#{root_url}listings"
    )

    @session_id = session.id
    end 
end


  # GET /listings/new
  def new
    @listing = current_user.listings.build 
  end

  # GET /listings/1/edit
  def edit
  end

  # POST /listings
  # POST /listings.json
  def create
    @listing = current_user.listings.build(listing_params)

    respond_to do |format|
      if @listing.save
        format.html { redirect_to @listing, notice: 'Listing was successfully created.' }
        format.json { render :show, status: :created, location: @listing }
      else
        format.html { render :new }
        format.json { render json: @listing.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /listings/1
  # PATCH/PUT /listings/1.json
  def update
    respond_to do |format|
      if @listing.update(listing_params)
        format.html { redirect_to @listing, notice: 'Listing was successfully updated.' }
        format.json { render :show, status: :ok, location: @listing }
      else
        format.html { render :edit }
        format.json { render json: @listing.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /listings/1
  # DELETE /listings/1.json
  def destroy
    @listing.destroy
    respond_to do |format|
      format.html { redirect_to listings_url, notice: 'Listing was successfully deleted.' }
      format.json { head :no_content }
    end
  end

 


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_listing
      @listing = Listing.find(params[:id])
      #@listing = current_user.listings.find(params[:id])#
    end
    
    # method to set user listing
    def set_user_listing
      id = params[:id]
      @listing = current_user.listings.find_by_id(id)
      if
       @listing == nil
        redirect_to listings_path
      end
  end

    # Only allow a list of trusted parameters through.
    def listing_params
      params.require(:listing).permit(:title, :description, :category_id, :suburb, :city, :price, :deposit, :availability, :picture, :user_id, :bought, :to, :from)
    end

  def set_category
    @categories = Category.all 
  end


end