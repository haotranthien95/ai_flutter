# Feature Specification: Multi-Vendor E-Commerce Marketplace

**Feature Branch**: `001-ecommerce-marketplace`  
**Created**: 2025-12-03  
**Updated**: 2025-12-04  
**Status**: In Progress  
**Scope**: Full-stack application (Flutter Mobile + FastAPI Python Backend)  
**Input**: Multi-vendor e-commerce application inspired by Shopee for Vietnamese market

## Project Structure

```
ai_flutter/
├── mobile/          # Flutter mobile application (iOS/Android)
├── backend/         # FastAPI Python REST API server
├── specs/           # Feature specifications and planning
├── brandstorm/      # Project ideation documents
└── README.md        # Project overview
```

## Clarifications

### Session 2025-12-03

- Q: Backend Architecture → A: REST API with separate backend service
- Q: Database Choice → A: PostgreSQL (relational database)
- Q: Real-Time Communication for Chat → A: WebSocket connection
- Q: Image Storage Solution → A: Hybrid: Cloud for product images, local for temporary uploads
- Q: Shipping Fee Calculation → A: Seller sets flat rate per order with optional free shipping threshold

## User Scenarios & Testing *(mandatory)*

<!--
  User stories are PRIORITIZED as user journeys ordered by importance and value delivery.
  Each story is INDEPENDENTLY TESTABLE - implementing any single story delivers viable functionality.
  This enables MVP-first development where P1 delivers core value, and subsequent priorities add features.
-->

---

### User Story 1 - Guest Product Discovery (Priority: P1) 🎯 MVP FOUNDATION

Guest users can browse the marketplace, view products, and see basic information without requiring an account. This is the absolute foundation that makes the marketplace visible to potential customers.

**Why this priority**: Without product discovery, there's no marketplace. This is the entry point that attracts users and demonstrates value before they commit to signing up. Essential for SEO, marketing, and user acquisition.

**Independent Test**: Deploy just this story - users can visit the app/website, browse categories, search products, view product details with images/prices/reviews, and see seller information. No account required.

**Acceptance Scenarios**:

1. **Given** I am a guest user on the home page, **When** I view the screen, **Then** I see featured categories, campaign banners, and recommended products
2. **Given** I am browsing the home page, **When** I tap on a category tile, **Then** I see a grid of products in that category
3. **Given** I am on a category page, **When** I apply filters (price range, rating, location, shipping options), **Then** the product list updates to show only matching items
4. **Given** I am viewing a product list, **When** I change sorting (relevance, newest, best-selling, price low-high, price high-low), **Then** products reorder accordingly
5. **Given** I am on any page with a search bar, **When** I type keywords, **Then** I see autocomplete suggestions in real-time
6. **Given** I enter a search term and submit, **When** results load, **Then** I see products matching my search with ability to filter and sort
7. **Given** I tap on a product card, **When** the product detail page loads, **Then** I see multiple images (swipeable gallery), price in VND, stock status, available variants (size/color), description, and seller info
8. **Given** I am viewing a product detail, **When** I scroll down, **Then** I see rating summary (average stars, total reviews) and detailed reviews with user photos and text
9. **Given** I see seller information on a product page, **When** displayed, **Then** I see seller name, rating, follower count, and number of products
10. **Given** I try to add a product to cart as a guest, **When** I tap "Add to Cart", **Then** I see a prompt to sign up or log in

---

### User Story 2 - Buyer Account & Authentication (Priority: P1) 🎯 MVP FOUNDATION

Users can create accounts, log in securely, and manage their basic profile and shipping addresses. This unlocks the ability to make purchases.

**Why this priority**: Authentication is required for transactions. Without accounts, users cannot buy anything. This is the second essential building block after discovery.

**Independent Test**: Users can complete the full registration flow (phone/email with OTP verification), log in, set up their profile with name and shipping address, then log out and log back in successfully.

**Acceptance Scenarios**:

1. **Given** I am a new user, **When** I tap "Sign Up" and enter phone number/email, **Then** I receive an OTP code for verification
2. **Given** I received an OTP, **When** I enter the correct code within the time limit, **Then** my account is created and verified
3. **Given** I have a verified account, **When** I complete profile setup (name, basic info), **Then** I can proceed to the app
4. **Given** I am logged in for the first time, **When** prompted to add a shipping address, **Then** I can enter address details (street, district, city, phone number) and save it
5. **Given** I am a returning user, **When** I enter my credentials on the login page, **Then** I am authenticated and taken to the home page
6. **Given** I am logged in, **When** I navigate to my profile, **Then** I see my name, phone/email, and can edit my information
7. **Given** I am in profile settings, **When** I tap "Manage Addresses", **Then** I see my saved addresses and can add/edit/delete them
8. **Given** I want to add a new address, **When** I fill in the address form and save, **Then** it appears in my address list and can be selected at checkout
9. **Given** I am logged in, **When** I tap "Log Out", **Then** I am logged out and returned to guest browsing mode
10. **Given** I forgot my password, **When** I use the "Forgot Password" flow with OTP, **Then** I can reset my password and log in with the new credentials

---

### User Story 3 - Shopping Cart & Simple Checkout (Priority: P1) 🎯 MVP FOUNDATION

Buyers can add products to cart, review their selections, and complete checkout with Cash on Delivery (COD) payment. This completes the minimum viable transaction flow.

**Why this priority**: This is the revenue-generating core. With stories 1, 2, and 3, you have a complete buyer journey: browse → register → purchase. This is the minimum viable marketplace.

**Independent Test**: Logged-in user adds multiple products (from different shops) to cart, sees items grouped by shop, applies basic shop vouchers if available, confirms shipping address, selects COD payment, and places an order successfully. Order appears in their order history.

**Acceptance Scenarios**:

1. **Given** I am logged in and viewing a product detail, **When** I select a variant and tap "Add to Cart", **Then** the item is added and cart icon shows updated count
2. **Given** I have items in my cart, **When** I navigate to the cart page, **Then** I see all items grouped by shop with product images, names, variants, quantities, and prices
3. **Given** I am on the cart page, **When** I adjust quantity for an item or remove it, **Then** the cart totals update immediately
4. **Given** I have items from multiple shops, **When** viewing my cart, **Then** each shop section shows separate subtotal and shipping fee
5. **Given** I want to apply a voucher, **When** I tap "Apply Voucher" for a shop, **Then** I see available shop vouchers and can select one to apply discount
6. **Given** I have valid items in cart, **When** I tap "Proceed to Checkout", **Then** I am taken to the checkout page
7. **Given** I am on the checkout page, **When** it loads, **Then** I see my default shipping address or can select/add a different one
8. **Given** I am reviewing my order, **When** I see the order summary, **Then** it shows product subtotals, discounts, shipping fees per shop, and final grand total in VND
9. **Given** I have confirmed my address and reviewed the order, **When** I select "Cash on Delivery" as payment method and tap "Place Order", **Then** the order is submitted successfully
10. **Given** my order is placed, **When** confirmation appears, **Then** I see order number, estimated delivery time, and order details, plus receive an in-app notification

---

### User Story 4 - Order Tracking & History (Priority: P2)

Buyers can view their order history, track order status through different stages, and see detailed information about each order.

**Why this priority**: After completing purchases (P1), buyers need visibility into their orders. This builds trust and reduces support inquiries. Essential for user retention.

**Independent Test**: User places an order (from P1-P3), then navigates to "My Orders" to see it listed. User can view order details showing items, status, tracking timeline, and seller information. Status updates as order progresses.

**Acceptance Scenarios**:

1. **Given** I am logged in, **When** I navigate to "My Orders", **Then** I see a list of all my orders sorted by most recent
2. **Given** I am viewing my order list, **When** I filter by status (Pending, Confirmed, Shipping, Completed, Cancelled), **Then** only orders with that status are displayed
3. **Given** I tap on an order, **When** the order detail page loads, **Then** I see order number, placement date, status, items purchased with quantities and prices, shipping address, and total amount
4. **Given** I am viewing order details, **When** I check tracking information, **Then** I see a timeline showing order progression (Pending → Confirmed → Packed → Shipping → Delivered)
5. **Given** my order status changes (e.g., seller confirms, shipping starts), **When** the update occurs, **Then** I receive an in-app notification and the order detail page reflects the new status
6. **Given** I have an order in "Pending" or "Confirmed" status, **When** I tap "Cancel Order", **Then** I see a confirmation dialog and can provide a reason
7. **Given** I confirm cancellation, **When** the request is processed, **Then** the order status changes to "Cancelled" and I see the cancellation confirmation
8. **Given** my order is delivered, **When** I view the order detail, **Then** I see a "Rate & Review" button for each product
9. **Given** I want to contact the seller about an order, **When** I tap "Contact Seller", **Then** I am taken to the chat interface with the seller with order context
10. **Given** I need to re-order, **When** I tap "Buy Again" on a completed order, **Then** all items from that order are added to my cart

---

### User Story 5 - Product Reviews & Ratings (Priority: P2)

Buyers can rate and review products after delivery, and all users (including guests) can read reviews to make informed decisions.

**Why this priority**: Reviews build trust and drive conversions. After order tracking (P2), this completes the buyer feedback loop, creating social proof for future buyers.

**Independent Test**: Buyer receives a delivered order, rates products (1-5 stars), writes review text, optionally uploads photos. Review appears on product page visible to all users including guests.

**Acceptance Scenarios**:

1. **Given** I have a completed/delivered order, **When** I view the order detail, **Then** I see "Rate & Review" buttons for each product
2. **Given** I tap "Rate & Review" for a product, **When** the rating screen opens, **Then** I can select 1-5 stars, write review text, and optionally upload photos (up to 5)
3. **Given** I have filled in my rating and review, **When** I tap "Submit", **Then** the review is saved and I see a confirmation message
4. **Given** I submitted a review, **When** I return to the product page, **Then** my review appears in the reviews section
5. **Given** I am viewing a product detail page (as any user type), **When** I scroll to reviews, **Then** I see the rating summary (average stars, total review count, breakdown by star level)
6. **Given** I am reading reviews, **When** displayed, **Then** each review shows reviewer name (or anonymous), star rating, review text, photos if any, and date posted
7. **Given** there are many reviews, **When** I want to filter, **Then** I can filter by star rating (e.g., show only 5-star, 4-star, etc.) or "With Photos"
8. **Given** I am viewing reviews, **When** I want to see most helpful feedback, **Then** I can sort by newest, highest rating, or lowest rating
9. **Given** I see a review with photos, **When** I tap on a photo, **Then** it opens in a fullscreen viewer where I can swipe through all review photos
10. **Given** I already reviewed a product, **When** I access the review form again, **Then** I can edit my existing review and update the rating/text/photos

---

### User Story 6 - Seller Shop Registration & Setup (Priority: P2)

Users can convert their buyer account to a seller account, register a shop with branding and details, and complete basic verification to start selling.

**Why this priority**: To have a marketplace, you need sellers. This is the entry point for supply side. Positioned after core buyer flows (P1) because buyers come first, but essential before sellers can list products.

**Independent Test**: Existing user navigates to "Become a Seller", fills out shop registration form (shop name, description, logo, cover image, address, policy acceptance), submits basic documents if required, and shop is created. User can now access seller dashboard.

**Acceptance Scenarios**:

1. **Given** I am a logged-in buyer, **When** I tap "Sell on [Platform]" or "Become a Seller", **Then** I am taken to the seller registration introduction page
2. **Given** I want to register as a seller, **When** I tap "Register Now", **Then** I see a form requesting shop name, description, category focus, and contact details
3. **Given** I am filling the shop registration form, **When** I upload a shop logo and cover image, **Then** I see previews and can adjust or re-upload
4. **Given** I complete the shop information, **When** I enter my shop address (for pickup and returns), **Then** I can search and select district/city and provide detailed address
5. **Given** I have filled all required fields, **When** I tap "Next", **Then** I am prompted to accept seller policies and platform terms
6. **Given** I accept the terms, **When** verification is required, **Then** I am prompted to upload business documents (ID, business license if applicable) or provide basic KYC info
7. **Given** I submit my shop registration, **When** processing completes, **Then** I see a confirmation screen stating my shop is under review or immediately approved (based on platform rules)
8. **Given** my shop is approved, **When** I log in, **Then** I see a new "Seller Center" option in my menu
9. **Given** I access Seller Center for the first time, **When** it loads, **Then** I see a dashboard with options: Add Product, Manage Orders, Shop Settings, and basic stats (initially zero)
10. **Given** I want to update shop information, **When** I navigate to Shop Settings, **Then** I can edit shop name, description, logo, cover image, address, and contact details

---

### User Story 7 - Seller Product Management (Priority: P2)

Sellers can create, edit, and manage product listings including title, description, images, variants, pricing, and stock levels.

**Why this priority**: Immediately after shop registration (P2), sellers need to list products. This is the supply creation that makes the marketplace functional. Together with P2 seller registration, this enables the supply side.

**Independent Test**: Seller logs into Seller Center, creates a new product with title, description, multiple images, category selection, price, stock quantity, and optional variants (size/color). Product becomes visible in the marketplace for buyers to discover and purchase.

**Acceptance Scenarios**:

1. **Given** I am in Seller Center, **When** I tap "Add Product", **Then** I see a product creation form
2. **Given** I am creating a product, **When** I fill in product name and description, **Then** I can use rich text formatting for description (bold, bullets, etc.)
3. **Given** I am adding product images, **When** I tap "Upload Images", **Then** I can select multiple images (up to 9) from my device and see them in order with ability to reorder or delete
4. **Given** I need to select a category, **When** I tap "Category", **Then** I see a hierarchical category picker and can drill down to the most specific category
5. **Given** I am setting price and stock, **When** I enter values, **Then** I input price in VND and stock quantity as a number, with validation for positive numbers
6. **Given** my product has variants (e.g., Size: S/M/L, Color: Red/Blue), **When** I add variants, **Then** I can create variant combinations and set individual price/stock for each combination
7. **Given** I have filled all required fields, **When** I tap "Save" or "Publish", **Then** the product is created and appears in my product list as "Active"
8. **Given** I want to edit a product, **When** I tap on a product in my list, **Then** I see the product edit form pre-filled with current data
9. **Given** I edit product details, **When** I save changes, **Then** the product listing is updated immediately in the marketplace
10. **Given** I want to temporarily hide a product, **When** I toggle the product status to "Inactive", **Then** the product is removed from buyer searches but remains in my product list for future reactivation
11. **Given** I need to update stock, **When** I edit stock quantity for a product or variant, **Then** the new stock level is saved and affects product availability (shows as out of stock if quantity reaches zero)
12. **Given** I have many products, **When** I view my product list, **Then** I can filter by status (Active/Inactive), search by product name, and see key info (thumbnail, name, price, stock)

---

### User Story 8 - Seller Order Management (Priority: P3)

Sellers can view incoming orders, confirm them, update order status (packed, ready for shipping), and manage the fulfillment process.

**Why this priority**: After products are listed (P2) and buyers start purchasing (P1), sellers need tools to fulfill orders. This completes the basic seller workflow. Critical for operations but comes after product listing since you need products before orders.

**Independent Test**: Buyer places an order for seller's product. Seller sees new order in Seller Center, confirms it, marks it as packed, and updates shipping status. Buyer sees status updates on their end.

**Acceptance Scenarios**:

1. **Given** I am a seller, **When** a buyer places an order for my products, **Then** I receive an in-app notification and the order appears in my "Orders" tab
2. **Given** I am in Seller Center Orders view, **When** I see my order list, **Then** orders are displayed with order number, buyer name, order date, total amount, and current status
3. **Given** I have orders in different states, **When** I filter by status (New, Confirmed, Packed, Shipping, Completed, Cancelled), **Then** only orders matching that status are shown
4. **Given** I tap on an order, **When** the order detail page opens, **Then** I see all items ordered, quantities, variants, buyer's shipping address, contact info, and payment method
5. **Given** I see a new order (status: New/Pending), **When** I tap "Confirm Order", **Then** the order status changes to "Confirmed" and the buyer receives a notification
6. **Given** an order is confirmed, **When** I prepare the items and tap "Mark as Packed", **Then** the order status updates to "Packed" and buyer is notified that their order is ready for pickup by shipping carrier
7. **Given** the order is picked up by courier, **When** I tap "Hand to Carrier" or update shipping status, **Then** the order status changes to "Shipping" and buyer can track it
8. **Given** a buyer requests cancellation or I need to cancel, **When** I tap "Cancel Order" and provide a reason, **Then** the order status changes to "Cancelled" and buyer is notified
9. **Given** I want to contact the buyer about an order, **When** I tap "Contact Buyer", **Then** I am taken to the chat interface with that buyer with order context
10. **Given** I need to handle many orders efficiently, **When** I select multiple orders with same status, **Then** I can perform bulk actions (e.g., bulk confirm, bulk mark as packed)

---

### User Story 9 - In-App Messaging (Buyer-Seller Chat) (Priority: P3)

Buyers and sellers can communicate via in-app chat to ask questions about products, discuss orders, and resolve simple issues.

**Why this priority**: Communication is essential for trust and support, but the basic transaction flow (P1-P2) works without it. Adds significant value for customer service and conversions. Positioned after core buyer and seller features.

**Independent Test**: Buyer opens a product and taps "Chat with Seller". Chat window opens, buyer sends a message, seller receives notification and responds. Both can see message history with timestamps.

**Acceptance Scenarios**:

1. **Given** I am a buyer viewing a product, **When** I tap "Chat with Seller" or "Contact Seller", **Then** a chat window opens with the seller
2. **Given** I am in a chat window, **When** I type a message and tap "Send", **Then** the message is sent and appears in the conversation with timestamp
3. **Given** I sent a message, **When** the seller responds, **Then** I receive a notification and can see the reply in the chat window
4. **Given** I am chatting about a specific product, **When** the chat opens from a product page, **Then** the product context (image, name, price) is shown at the top of the chat
5. **Given** I am a seller, **When** a buyer sends me a message, **Then** I receive an in-app notification and the chat appears in my "Messages" inbox
6. **Given** I am a seller in my Messages inbox, **When** I view the list, **Then** I see all conversations with buyers, showing last message preview, timestamp, and unread indicator
7. **Given** I tap on a conversation, **When** the chat opens, **Then** I can see full message history and respond to the buyer
8. **Given** I am chatting with a buyer, **When** I want to share a product, **Then** I can tap "Send Product" to attach a product link/card to my message
9. **Given** I receive a product link in chat, **When** I tap on it, **Then** I am taken to that product's detail page
10. **Given** I am in a chat, **When** I need to reference an order, **Then** I can send order details or the chat shows order context if initiated from an order page
11. **Given** messages are being exchanged, **When** either party sends a message, **Then** both users see real-time updates without needing to refresh
12. **Given** I have multiple unread chats, **When** I view my Messages inbox, **Then** unread chats are highlighted and show a count badge

---

### User Story 10 - Shop Vouchers & Promotions (Priority: P3)

Sellers can create and manage shop-specific vouchers (discount codes) with conditions like minimum spend, discount type (percentage/fixed amount), and validity period.

**Why this priority**: Promotions drive sales and competitiveness, but marketplace works without them. This is a growth feature that sellers can use once they have products and orders flowing (after P2-P3).

**Independent Test**: Seller creates a voucher with 10% discount, minimum spend 100k VND, valid for 7 days. Buyer browses seller's products, adds items totaling 100k+, applies voucher at cart, sees discount applied, and completes purchase with reduced price.

**Acceptance Scenarios**:

1. **Given** I am a seller in Seller Center, **When** I navigate to "Promotions" or "Vouchers", **Then** I see a list of my existing vouchers and an option to "Create Voucher"
2. **Given** I tap "Create Voucher", **When** the form opens, **Then** I can enter voucher code (or auto-generate), discount type (percentage or fixed amount), and discount value
3. **Given** I am creating a voucher, **When** I set conditions, **Then** I can specify minimum spend amount, usage limit per customer, total usage limit, and start/end dates
4. **Given** I complete the voucher form, **When** I tap "Create", **Then** the voucher is saved and becomes active during its validity period
5. **Given** I want to promote the voucher, **When** I view voucher details, **Then** I can copy the voucher code to share with customers or display on my shop page
6. **Given** a buyer is viewing my shop or products, **When** there are active vouchers, **Then** the buyer can see available vouchers on the shop page or product listings
7. **Given** I am a buyer adding items to cart from a shop, **When** I reach the cart/checkout, **Then** I see available vouchers for that shop
8. **Given** I am at checkout, **When** I tap "Apply Voucher" for a shop, **Then** I see a list of applicable vouchers and can select one
9. **Given** I select a voucher, **When** my cart meets the conditions (e.g., minimum spend), **Then** the discount is applied and subtotal reflects the reduced amount
10. **Given** I select a voucher, **When** my cart doesn't meet conditions (e.g., below minimum spend), **Then** I see a message explaining the requirement and the voucher is not applied
11. **Given** I am a seller, **When** I view my voucher list, **Then** I can see usage statistics (how many times used, remaining uses) and can edit or deactivate vouchers
12. **Given** a voucher has expired or reached usage limit, **When** a buyer tries to apply it, **Then** they see an error message that the voucher is no longer valid

---

### User Story 11 - Seller Shop Analytics & Insights (Priority: P4)

Sellers can view basic performance metrics for their shop including total orders, revenue, top-selling products, cancellation rate, and recent reviews.

**Why this priority**: Analytics help sellers optimize their business, but the core selling functionality (P2-P3) works without them. Nice-to-have for seller retention and growth. Can be basic in MVP and enhanced later.

**Independent Test**: Seller accesses dashboard and sees summary cards: total orders this month, total revenue, top 5 selling products, average rating, and cancellation rate. Data updates as new orders and reviews come in.

**Acceptance Scenarios**:

1. **Given** I am a seller, **When** I open Seller Center dashboard, **Then** I see key metrics displayed: total orders, total revenue (VND), number of active products, and shop rating
2. **Given** I am viewing dashboard metrics, **When** I select a time period (Today, This Week, This Month), **Then** the metrics update to reflect data for that period
3. **Given** I want to see product performance, **When** I scroll to "Top Selling Products", **Then** I see a list of my top 5 products ranked by quantity sold with revenue for each
4. **Given** I want to understand order flow, **When** I view order statistics, **Then** I see breakdown by status (Pending, Confirmed, Completed, Cancelled) with counts and percentages
5. **Given** I am monitoring shop health, **When** I check cancellation rate, **Then** I see percentage of cancelled orders and can tap to view reasons
6. **Given** I want to see customer feedback, **When** I navigate to "Recent Reviews", **Then** I see the latest reviews for my products with ratings, text, and which product was reviewed
7. **Given** I want to track daily performance, **When** I view revenue chart, **Then** I see a simple line or bar chart showing daily revenue for the selected period
8. **Given** I want to see order trends, **When** I view order volume chart, **Then** I see number of orders placed per day over the selected period
9. **Given** I need to analyze a specific product, **When** I tap on a product in top sellers or search my product list, **Then** I see detailed stats for that product (views, orders, revenue, rating)
10. **Given** I want to compare performance, **When** viewing metrics, **Then** I can see comparison to previous period (e.g., "This Month vs Last Month") with percentage change

---

### User Story 12 - Favorite Products & Shop Following (Priority: P4)

Buyers can favorite/bookmark products to save for later and follow shops to get updates about new products and promotions.

**Why this priority**: Enhances engagement and retention, but not essential for core transaction flow (P1). Good for building user loyalty and repeat purchases. Lower priority than order management and communication.

**Independent Test**: Buyer favorites several products by tapping heart icon on product cards/detail pages. Favorites appear in "My Favorites" list. Buyer follows a shop and receives notification when shop adds new products or creates promotions.

**Acceptance Scenarios**:

1. **Given** I am a buyer viewing a product, **When** I tap the heart/favorite icon, **Then** the product is added to my favorites list and the icon fills in
2. **Given** a product is already favorited, **When** I tap the heart icon again, **Then** the product is removed from favorites and the icon becomes outline only
3. **Given** I have favorited products, **When** I navigate to "My Favorites" or "Wishlist", **Then** I see all my favorited products with thumbnail, name, price, and current availability
4. **Given** I am viewing my favorites list, **When** a product price drops or goes on sale, **Then** I see a visual indicator (e.g., "Price Drop" badge)
5. **Given** I want to purchase favorites, **When** I tap a product in my favorites, **Then** I am taken to the product detail page and can add to cart
6. **Given** I want to manage favorites, **When** I am in my favorites list, **Then** I can select multiple items and remove them in bulk
7. **Given** I am viewing a shop page, **When** I tap "Follow Shop" button, **Then** the shop is added to my followed shops list and the button changes to "Following"
8. **Given** I am following a shop, **When** I tap "Following" button again, **Then** I unfollow the shop
9. **Given** I am following shops, **When** I navigate to "Following" or "My Shops", **Then** I see a list of all shops I follow with shop logo, name, and product count
10. **Given** I follow a shop, **When** the shop adds a new product, **Then** I receive an in-app notification (if notifications enabled)
11. **Given** I follow a shop, **When** the shop creates a new voucher or promotion, **Then** I receive a notification about the promotion
12. **Given** I want to quickly access followed shops, **When** I am on the home page, **Then** I see a "Following" section showing recent products from shops I follow

---

### User Story 13 - Platform Admin Content Management (Priority: P4)

Platform administrators can manage homepage content (banners, featured categories), create platform-wide campaigns, and moderate product listings.

**Why this priority**: Admin tools are important for platform health, but the marketplace can function with minimal admin intervention initially. Early focus should be on buyer and seller features. This can be basic initially and expanded over time.

**Independent Test**: Admin logs into admin panel, uploads a banner image for a campaign, sets link destination, and publishes it. Banner appears on homepage for all users. Admin can search products, view flagged items, and deactivate a product if needed.

**Acceptance Scenarios**:

1. **Given** I am a platform admin, **When** I log into the admin panel, **Then** I see dashboard with key platform metrics (total users, total products, total orders, active sellers)
2. **Given** I want to update homepage content, **When** I navigate to "Homepage Management", **Then** I can add/edit/remove banner slides with images, titles, and link destinations
3. **Given** I am creating a banner, **When** I upload an image and set a link, **Then** I can preview how it looks and set display order and duration
4. **Given** I save homepage changes, **When** I publish, **Then** the updated content appears immediately on the homepage for all users
5. **Given** I want to feature specific categories, **When** I access "Category Management", **Then** I can set featured categories that appear prominently on the homepage
6. **Given** I want to create a platform campaign, **When** I navigate to "Campaigns", **Then** I can create a campaign (e.g., "Flash Sale", "Free Shipping Day") with title, description, and participating products/shops
7. **Given** I need to moderate products, **When** I search for products in admin panel, **Then** I can view all products across the platform with filters by category, status, seller, and flags
8. **Given** a product is reported or violates policies, **When** I review the product details, **Then** I can deactivate it, contact the seller, or remove it entirely
9. **Given** I want to manage sellers, **When** I view seller list, **Then** I can see all registered shops with status (Active, Under Review, Suspended) and can approve, suspend, or request additional verification
10. **Given** I need to review reports, **When** I navigate to "Reports", **Then** I see user-reported content (products, reviews, chat messages) with reason, reporter info, and can take action (dismiss, remove content, warn/ban user)

---

### User Story 14 - Push Notifications & Notification Center (Priority: P4)

Users receive push notifications for important events (order updates, messages, promotions) and can view notification history in a notification center.

**Why this priority**: Notifications improve engagement and keep users informed, but the app functions without them (users can manually check orders, messages, etc.). Good for retention but not critical for MVP.

**Independent Test**: User enables notifications. When seller confirms an order, user receives push notification. Tapping notification opens the order detail. User can view all notifications in notification center with icons indicating notification type.

**Acceptance Scenarios**:

1. **Given** I am a new user, **When** I first open the app or after login, **Then** I am prompted to enable push notifications with clear explanation of benefits
2. **Given** I enable notifications, **When** I receive a notification on my device, **Then** it appears as a push notification with app icon, title, and message preview
3. **Given** I receive a push notification, **When** I tap on it, **Then** the app opens to the relevant screen (e.g., order detail, chat, product page)
4. **Given** I am a buyer, **When** my order status changes (confirmed, shipping, delivered), **Then** I receive a push notification with the update
5. **Given** I am a seller, **When** I receive a new order, **Then** I receive a push notification alerting me
6. **Given** I am chatting with someone, **When** I receive a new message while the app is in background, **Then** I receive a push notification with message preview
7. **Given** I follow a shop, **When** the shop creates a new promotion or adds popular products, **Then** I receive a notification (respecting frequency limits)
8. **Given** I am in the app, **When** I tap the notification bell icon, **Then** I see the notification center with all my notifications listed chronologically
9. **Given** I am viewing notification center, **When** I see a notification, **Then** it shows icon/type, title, message, and timestamp, with unread notifications highlighted
10. **Given** I tap a notification in notification center, **When** selected, **Then** I am taken to the relevant screen and the notification is marked as read
11. **Given** I want to manage notifications, **When** I go to Settings > Notifications, **Then** I can toggle notification types on/off (orders, messages, promotions, etc.)
12. **Given** I want to clear notifications, **When** I am in notification center, **Then** I can mark all as read or delete notifications individually or in bulk

---

### User Story 15 - Flash Sales & Time-Limited Campaigns (Priority: P5)

Platform can run flash sales with countdown timers, limited stock, and special pricing for featured products during specific time windows.

**Why this priority**: Flash sales drive engagement and urgency, but require existing buyer base and seller participation. This is a growth/marketing feature best added after core marketplace is mature. Nice-to-have for GMV growth.

**Independent Test**: Admin creates a flash sale campaign for selected products with 20% discount, starts at 12:00 PM, lasts 2 hours, limited quantity. Homepage shows flash sale banner with countdown. Buyers see special prices, timer, and stock indicator. Sale ends automatically and prices revert.

**Acceptance Scenarios**:

1. **Given** I am an admin, **When** I create a flash sale campaign, **Then** I can select products, set discount percentage, choose start/end time, and limit quantities available
2. **Given** a flash sale is scheduled, **When** the start time arrives, **Then** the flash sale goes live automatically and featured products show discounted prices
3. **Given** a flash sale is active, **When** buyers view the homepage, **Then** they see a prominent flash sale banner/section with countdown timer
4. **Given** I am a buyer viewing flash sale, **When** I tap on the flash sale section, **Then** I see all participating products with original price crossed out, sale price, discount percentage, and remaining stock indicator
5. **Given** I am viewing a flash sale product, **When** I check availability, **Then** I see a live stock counter (e.g., "Only 23 left!") that updates as others purchase
6. **Given** I want to purchase a flash sale item, **When** I add it to cart and checkout, **Then** the flash sale price is locked for my cart item (for a limited time to complete checkout)
7. **Given** I have flash sale items in cart, **When** the sale ends or stock runs out before I checkout, **Then** I see a warning that the item is no longer available at sale price or is out of stock
8. **Given** I am viewing a flash sale, **When** the countdown reaches zero, **Then** the sale ends, prices revert to normal, and the flash sale section is removed or shows "Ended"
9. **Given** a flash sale item sells out, **When** I try to view it, **Then** it shows "Sold Out" and I cannot add it to cart, but I can set a "Notify Me" alert for future sales
10. **Given** I missed a flash sale, **When** I view past campaigns, **Then** I can see "Upcoming Sales" section to prepare for the next one

---

### Edge Cases

- **What happens when a buyer's delivery address is invalid or incomplete?**
  - Checkout process should validate addresses with clear error messages highlighting missing/invalid fields.
  - Allow buyer to edit or select different address before order placement.
  - If address issues are discovered after order placement, seller or buyer support can contact buyer to update.

- **How does the system handle stock discrepancies (overselling)?**
  - Implement optimistic locking: when buyer adds to cart, stock is soft-reserved for limited time (e.g., 15 minutes).
  - During checkout, re-validate stock availability and show error if insufficient stock remains.
  - Seller should receive warning if stock levels are low or reach zero to prevent overselling.

- **What happens when payment method (COD) fails or buyer refuses delivery?**
  - For COD refusal: Order is marked as "Failed Delivery" and can be returned to seller.
  - Buyer may be charged return shipping fee or face penalties per platform policy (future feature).
  - Repeated refusals may flag buyer account for review.

- **How are disputes between buyers and sellers handled initially?**
  - Buyer and seller communicate via chat to attempt resolution first.
  - If unresolved, buyer can open a dispute/report through order detail page.
  - Admin receives dispute report and can mediate, request evidence, and make decisions (refund, return, seller warning).

- **What happens when a seller doesn't confirm an order within reasonable time?**
  - Platform policy sets auto-cancellation timer (e.g., 24-48 hours).
  - If seller doesn't confirm within timeframe, order is auto-cancelled and buyer is notified.
  - Repeated timeouts may affect seller rating and visibility.

- **How does the platform handle fake reviews or review manipulation?**
  - Buyers can only review products they actually purchased (verified purchase badge).
  - Implement report mechanism for suspicious reviews.
  - Admin can review flagged content and remove fake reviews, warn or ban offending accounts.

- **What happens when a voucher is applied to cart but one item becomes unavailable?**
  - System recalculates cart total without the unavailable item.
  - Check if voucher minimum spend is still met; if not, show warning and remove voucher application.
  - Buyer can choose to add more items to meet threshold or proceed without voucher.

- **How are refunds handled when COD is the payment method?**
  - For COD, no online payment was made, so no electronic refund needed.
  - If order is cancelled before delivery, no payment collected, no refund necessary.
  - If return/refund after delivery, seller may need to send money back via bank transfer (manual process initially).

- **What happens if a buyer's phone number or email changes?**
  - User can update phone/email in profile settings.
  - If updating phone, require OTP verification to new number.
  - If updating email, send verification link to new email.
  - Ensure old credentials are kept until new ones are verified to prevent lockout.

- **How does the system handle multiple concurrent edits to product stock by seller?**
  - Use optimistic concurrency control with version numbers or timestamps.
  - If conflict detected (e.g., two edits at same time), show error and require seller to refresh and re-submit.
  - For critical operations (order placement reducing stock), use database-level locking to ensure consistency.

---

## Requirements *(mandatory)*

### Functional Requirements

**Authentication & User Management**
- **FR-001**: System MUST support user registration via phone number or email with OTP verification
- **FR-002**: System MUST support user login with phone/email and password
- **FR-003**: System MUST support password reset flow with OTP verification
- **FR-004**: System MUST allow users to manage multiple shipping addresses with default address selection
- **FR-005**: System MUST allow users to update profile information (name, phone, email)
- **FR-006**: System MUST support role-based access (Guest, Buyer, Seller, Admin) with appropriate permissions

**Product Discovery & Browsing**
- **FR-007**: System MUST display homepage with categories, banners, flash sales, and recommended products
- **FR-008**: System MUST allow users to browse products by category with hierarchical navigation
- **FR-009**: System MUST provide search functionality with keyword matching and autocomplete suggestions
- **FR-010**: System MUST allow filtering products by price range, rating, location, and shipping options
- **FR-011**: System MUST allow sorting products by relevance, newest, best-selling, and price (ascending/descending)
- **FR-012**: System MUST display product details including images (gallery), price, stock status, variants, description, seller info
- **FR-013**: System MUST display product ratings and reviews with filtering and sorting options
- **FR-014**: System MUST show seller information including rating, follower count, and product count

**Shopping Cart & Checkout**
- **FR-015**: System MUST allow logged-in buyers to add products (with variant selection) to shopping cart
- **FR-016**: System MUST group cart items by shop with separate subtotals and shipping fees
- **FR-017**: System MUST allow buyers to adjust quantities, select/deselect items, and remove items from cart
- **FR-018**: System MUST support applying shop vouchers with validation of discount conditions
- **FR-019**: System MUST support checkout flow with address confirmation, payment method selection, and order summary
- **FR-020**: System MUST support Cash on Delivery (COD) payment method for initial launch
- **FR-021**: System MUST generate unique order number and confirmation upon successful order placement
- **FR-022**: System MUST calculate final total including product prices, discounts, and shipping fees in VND

**Order Management (Buyer)**
- **FR-023**: System MUST display buyer's order history with filtering by status
- **FR-024**: System MUST show order details including items, quantities, prices, address, total, and current status
- **FR-025**: System MUST provide order status tracking with timeline (Pending → Confirmed → Packed → Shipping → Delivered)
- **FR-026**: System MUST allow buyers to cancel orders within allowed timeframe (before seller confirmation)
- **FR-027**: System MUST allow buyers to rate and review products after delivery with star rating (1-5), text, and photos
- **FR-028**: System MUST notify buyers of order status changes via in-app notifications

**Seller Management**
- **FR-029**: System MUST allow users to register as sellers with shop information (name, description, logo, cover image, address)
- **FR-030**: System MUST support seller account approval workflow (immediate or admin review based on policy)
- **FR-031**: System MUST provide Seller Center dashboard with access to products, orders, and shop settings

**Product Management (Seller)**
- **FR-032**: System MUST allow sellers to create product listings with title, description, category, price, stock, and images (up to 9)
- **FR-033**: System MUST support product variants (e.g., size, color) with individual pricing and stock per variant
- **FR-034**: System MUST allow sellers to edit existing product information and images
- **FR-035**: System MUST allow sellers to toggle product status (Active/Inactive) to control marketplace visibility
- **FR-036**: System MUST update product availability based on stock levels (show "Out of Stock" when quantity = 0)
- **FR-037**: System MUST allow sellers to manage product list with search and filtering capabilities

**Order Management (Seller)**
- **FR-038**: System MUST notify sellers of new orders via in-app notifications
- **FR-039**: System MUST allow sellers to view and filter orders by status
- **FR-040**: System MUST allow sellers to confirm orders, changing status from Pending to Confirmed
- **FR-041**: System MUST allow sellers to update order status (Packed, Shipping, Completed)
- **FR-042**: System MUST allow sellers to cancel orders with reason before fulfillment
- **FR-043**: System MUST support bulk actions for order management (bulk confirm, bulk status update)

**Messaging & Communication**
- **FR-044**: System MUST provide in-app chat functionality between buyers and sellers
- **FR-045**: System MUST support real-time message delivery with notifications when app is in background
- **FR-046**: System MUST display message history with timestamps and read/unread indicators
- **FR-047**: System MUST allow sharing product context in chat (product cards/links)
- **FR-048**: System MUST provide Messages inbox for sellers showing all buyer conversations

**Shop Features**
- **FR-049**: System MUST allow buyers to follow shops to receive updates
- **FR-050**: System MUST allow buyers to favorite/bookmark products for later viewing
- **FR-051**: System MUST display shop page with products, ratings, and follower count
- **FR-052**: System MUST allow sellers to create shop vouchers with discount type (percentage/fixed), conditions (min spend, usage limits), and validity period
- **FR-053**: System MUST display available shop vouchers to buyers during shopping and checkout
- **FR-054**: System MUST validate and apply voucher discounts at checkout
- **FR-055**: System MUST allow sellers to configure flat-rate shipping fee per order in shop settings
- **FR-056**: System MUST allow sellers to set optional free shipping threshold (minimum order amount)
- **FR-057**: System MUST calculate and display shipping fees per shop in cart and checkout
- **FR-058**: System MUST waive shipping fee when order subtotal meets or exceeds shop's free shipping threshold

**Seller Analytics**
- **FR-059**: System MUST display seller dashboard with key metrics (total orders, revenue, active products, shop rating)
- **FR-060**: System MUST provide time-period filtering for analytics (Today, This Week, This Month)
- **FR-061**: System MUST show top-selling products with quantities and revenue
- **FR-062**: System MUST display order statistics by status with counts and percentages
- **FR-063**: System MUST show recent reviews and ratings for seller's products

**Platform Administration**
- **FR-064**: System MUST provide admin panel with platform-wide metrics (users, products, orders, sellers)
- **FR-065**: System MUST allow admins to manage homepage content (banners, featured categories)
- **FR-066**: System MUST allow admins to create and manage platform campaigns
- **FR-067**: System MUST allow admins to search and moderate product listings (deactivate, remove)
- **FR-068**: System MUST allow admins to manage seller accounts (approve, suspend, verify)
- **FR-069**: System MUST provide reporting system for users to flag inappropriate content (products, reviews, chats)
- **FR-070**: System MUST allow admins to review reports and take action (remove content, warn users, ban accounts)

**Notifications**
- **FR-071**: System MUST support push notifications for order updates, messages, and promotions
- **FR-072**: System MUST provide notification center showing notification history with type indicators
- **FR-073**: System MUST allow users to configure notification preferences by type
- **FR-074**: System MUST mark notifications as read when viewed and support bulk actions

**Flash Sales & Campaigns**
- **FR-075**: System MUST support time-limited flash sales with countdown timers
- **FR-076**: System MUST display flash sale products with discounted prices and remaining stock indicators
- **FR-077**: System MUST automatically start and end flash sales based on configured schedule
- **FR-078**: System MUST reserve flash sale items in cart with time limit for checkout completion

### Key Entities

- **User**: Represents all platform users with roles (Guest, Buyer, Seller, Admin), authentication credentials, profile information, and addresses
- **Shop**: Seller's storefront with name, description, branding (logo, cover), rating, follower count, and status
- **Product**: Sellable items with title, description, category, price, stock, images, variants, ratings, and active/inactive status
- **ProductVariant**: Specific configurations of products (e.g., Size: M, Color: Red) with individual price and stock
- **Category**: Hierarchical product classification for browsing and organization
- **Cart**: Temporary collection of products a buyer intends to purchase, grouped by shop
- **Order**: Transaction record containing ordered items, buyer info, shipping address, payment method, status, and timestamps
- **OrderItem**: Individual product within an order with quantity, variant, price at purchase time
- **Review**: Buyer feedback on products with rating (1-5 stars), text, photos, and verified purchase indicator
- **Voucher**: Discount code created by sellers with type (percentage/fixed), conditions (min spend, usage limits), and validity period
- **Message**: Chat message between buyer and seller with text content, timestamp, sender/receiver, and read status
- **Notification**: System notification for users with type, title, message, related entity (order, product), timestamp, and read status
- **Campaign**: Platform or shop-level promotional event (flash sales, free shipping) with participating products and time constraints
- **Report**: User-submitted flag for inappropriate content with reason, reporter, reported entity, and admin review status

### Technical Architecture

**Backend**: FastAPI Python REST API
- Asynchronous Python web framework built on Starlette and Pydantic
- Automatic API documentation with OpenAPI/Swagger UI
- Type hints and data validation with Pydantic models
- High performance with async/await support
- JWT-based authentication with python-jose
- Password hashing with passlib and bcrypt
- Structured logging with Python logging module
- Testing with pytest and httpx async client
- Enables rapid development with automatic request validation

**Database**: PostgreSQL (relational database)
- ACID transactions ensure data consistency for orders and payments
- Relational model fits structured e-commerce data (users, products, orders, relationships)
- Strong support for complex queries (filtering, sorting, analytics)
- JSON column support for flexible product attributes and variant data
- Battle-tested for e-commerce scalability
- SQLAlchemy ORM for database interactions
- Alembic for database migrations

**Real-Time Communication**: WebSocket for chat messaging
- FastAPI native WebSocket support for buyer-seller chat
- Bidirectional real-time communication between buyers and sellers
- Low-latency message delivery (<3 seconds per SC-019)
- Persistent connection for active chat sessions
- Fallback to REST API for message history retrieval and offline messages
- Push notifications used when WebSocket connection is not active

**Image Storage**: Hybrid approach
- Cloud storage (AWS S3, Google Cloud Storage, or equivalent) for finalized product images, review photos, shop logos, and banners
- CDN integration for fast global image delivery (meets SC-014: <2 seconds load time)
- Local backend storage for temporary uploads during processing (validation, resizing, optimization)
- After processing, images are uploaded to cloud storage and local copies are deleted
- Database stores only image URLs/references, not binary data
- Image optimization pipeline with Pillow: resize to multiple resolutions, compress, generate thumbnails
- Async image processing to avoid blocking API requests

**Shipping Fee Calculation**: Seller-defined flat rate
- Each seller configures a flat shipping fee per order in their shop settings
- Sellers can optionally set a "Free Shipping Threshold" (minimum order amount for free shipping)
- At checkout, system applies seller's shipping fee for each shop's items
- If buyer's subtotal from a shop meets/exceeds free shipping threshold, shipping fee is waived for that shop
- Future enhancement: Integration with logistics carriers for dynamic weight/distance-based pricing
- Shipping fees displayed in VND and clearly shown in cart grouped by shop

**Backend Technology Stack**:
- **Framework**: FastAPI 0.100+
- **ORM**: SQLAlchemy 2.0+ with async support
- **Database Driver**: asyncpg (PostgreSQL async driver)
- **Migrations**: Alembic
- **Authentication**: python-jose (JWT), passlib (password hashing)
- **Validation**: Pydantic v2
- **Testing**: pytest, pytest-asyncio, httpx
- **Image Processing**: Pillow
- **Background Tasks**: FastAPI BackgroundTasks or Celery for heavy operations
- **API Documentation**: Auto-generated OpenAPI/Swagger UI
- **CORS**: FastAPI CORS middleware for Flutter app communication

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

**User Acquisition & Engagement**
- **SC-001**: Guest users can browse and view products within 3 seconds of app launch on 4G connection
- **SC-002**: New users can complete registration and account verification in under 2 minutes
- **SC-003**: 80% of product searches return relevant results within the first page (top 20 items)
- **SC-004**: Users can navigate from home page to product detail in maximum 3 taps

**Transaction Success**
- **SC-005**: Logged-in buyers can complete checkout flow (from cart to order confirmation) in under 3 minutes
- **SC-006**: 90% of orders are successfully placed without technical errors during checkout
- **SC-007**: Buyers receive order confirmation and initial status notification within 30 seconds of order placement
- **SC-008**: Order status updates reflect in buyer's order tracking within 1 minute of seller action

**Seller Efficiency**
- **SC-009**: New sellers can complete shop registration and list their first product within 10 minutes
- **SC-010**: Sellers can confirm orders within 3 taps from receiving notification
- **SC-011**: Sellers receive new order notifications within 30 seconds of buyer order placement
- **SC-012**: Sellers can create and activate a shop voucher in under 2 minutes

**Platform Performance**
- **SC-013**: App maintains 60fps scrolling performance on product lists and category pages
- **SC-014**: Product image galleries load and display within 2 seconds on 4G connection
- **SC-015**: Search autocomplete suggestions appear within 300ms of keystroke
- **SC-016**: Cart updates (add/remove/quantity change) reflect immediately (<500ms) with visual feedback

**Trust & Quality**
- **SC-017**: Product listings display complete seller information (rating, reviews, response rate) 100% of the time
- **SC-018**: Buyers can successfully submit product reviews with photos within 2 minutes
- **SC-019**: In-app messages between buyers and sellers are delivered in real-time (<3 seconds) when both are online
- **SC-020**: System prevents stock overselling by validating availability at checkout with <1% error rate

**Business Metrics**
- **SC-021**: Platform supports at minimum 1000 concurrent users without performance degradation
- **SC-022**: New sellers can onboard and list products with <10% dropout rate during registration
- **SC-023**: Voucher application at checkout increases average order value by measurable percentage (to be baselined)
- **SC-024**: Users can complete the buyer journey (browse → register → purchase → review) independently without support assistance in >85% of cases

**Accessibility & Usability**
- **SC-025**: All critical user flows (search, add to cart, checkout) are accessible with screen readers (VoiceOver/TalkBack)
- **SC-026**: Vietnamese UI text displays correctly with proper diacritics and formatting
- **SC-027**: Error messages are clear, actionable, and localized in Vietnamese
- **SC-028**: Users can recover from common errors (network failures, validation errors) without losing progress (e.g., cart persists)

---

## Constitution Check

This feature specification has been validated against the **AI Flutter Constitution v1.0.0**. Below is the compliance verification:

### ✅ I. Widget Composition & Reusability
- **Compliant**: Feature will be built using composable widgets following Flutter best practices
- **Implementation Plan**: Product cards, cart items, order status displays, review components, and chat bubbles will be reusable widgets
- **Validation**: Each screen (ProductDetailScreen, CartScreen, CheckoutScreen, etc.) will decompose into focused, single-purpose widgets with max 3-4 nesting levels

### ✅ II. State Management Clarity
- **Compliant**: State management approach will be defined during planning phase
- **Proposed Approach**: Local UI state (form inputs, filters) uses setState; shared state (cart, user session, orders) uses Provider or Riverpod; consistent pattern across all features
- **Validation**: State mutations will be centralized in dedicated state management classes (CartProvider, OrderProvider, UserProvider) for traceability

### ✅ III. Test-Driven Development (NON-NEGOTIABLE)
- **Compliant**: User stories are designed to be independently testable
- **Test Coverage Plan**: 
  - Widget tests for all custom UI components (product cards, forms, buttons)
  - Integration tests for each user journey (P1: guest browsing, P1: registration, P1: checkout, P2: order tracking, etc.)
  - Unit tests for business logic (voucher validation, price calculation, stock management)
- **Validation**: Tests will be written FIRST before implementation, must fail (Red), then implementation proceeds (Green), followed by refactoring

### ✅ IV. Performance-First Mobile Development
- **Compliant**: Success criteria include specific performance targets (60fps, 2-3 second load times)
- **Performance Strategies**:
  - Use ListView.builder for product lists and order lists
  - Implement image caching for product images (cached_network_image package)
  - Use const constructors for static widgets (category tiles, icons)
  - Optimize product search with debouncing (300ms per SC-015)
  - Profile performance with Flutter DevTools during development
- **Validation**: Performance will be measured and verified against SC-013 through SC-016 before feature completion

### ✅ V. AI Integration Patterns
- **Not Applicable in Initial Version**: Current specification focuses on core marketplace functionality
- **Future Consideration**: When AI features are added (product recommendations, smart search, chatbot assistance), they will follow:
  - Async operations with loading states
  - Graceful error handling and offline fallbacks
  - User cancellation options for long operations
  - Response streaming where applicable

### ✅ VI. Platform-Aware Development
- **Compliant**: Specification explicitly targets iOS and Android with responsive web
- **Platform Considerations**:
  - Use Material Design widgets as base (primary target: Android for Vietnamese market)
  - Implement Cupertino-style navigation for iOS where appropriate
  - Test camera/photo upload for product images and reviews on both platforms
  - Handle platform permissions (camera, notifications) with proper error states
  - Verify push notifications work on both iOS (APNS) and Android (FCM)
- **Validation**: Both iOS simulator/device and Android emulator/device testing required before marking features complete (per Testing Gates in constitution)

### ⚠️ Complexity Considerations
- **Large Feature Scope**: This is an extensive marketplace with 15 prioritized user stories
- **Mitigation**: Stories are independently testable and prioritized (P1-P5) enabling incremental delivery. MVP focuses on P1 stories only (guest discovery, authentication, checkout, order tracking).
- **External Dependencies**: Push notifications, image storage, potential payment gateway integrations
- **Mitigation**: Architecture will abstract external services behind interfaces for testability and future replacement

### 📋 Technical Standards Alignment
- **Flutter SDK**: 3.5.4+ (as specified in constitution)
- **Code Organization**: Will follow constitution structure:
  ```
  lib/
  ├── features/
  │   ├── auth/ (User Story 2)
  │   ├── product_discovery/ (User Story 1)
  │   ├── cart_checkout/ (User Story 3)
  │   ├── orders/ (User Stories 4, 8)
  │   ├── reviews/ (User Story 5)
  │   ├── seller/ (User Stories 6, 7, 11)
  │   ├── messaging/ (User Story 9)
  │   ├── promotions/ (User Stories 10, 15)
  │   └── admin/ (User Story 13)
  ├── core/ (shared utilities, constants, API clients)
  └── widgets/ (shared reusable components)
  ```
- **Linting**: flutter_lints enforced, analysis_options.yaml configured
- **Documentation**: Dartdoc comments required for all public APIs; feature specs maintained in .specify/specs/001-ecommerce-marketplace/

### ✅ Quality Assurance Gates
Before feature completion, all constitution testing gates must pass:
1. ✅ All widget tests pass (TDD compliance)
2. ✅ All integration tests for user journeys pass (P1-P5 as implemented)
3. ✅ Manual testing on iOS simulator/device
4. ✅ Manual testing on Android emulator/device
5. ✅ Performance profiling confirms 60fps, <3s load times (SC-013 to SC-016)
6. ✅ Accessibility: Screen reader navigation verified (SC-025)
7. ✅ Code review completed and constitutional compliance verified

---

**Next Steps**: Proceed to `/speckit.plan` to create implementation plan with technical research, architecture decisions, and phased task breakdown.
