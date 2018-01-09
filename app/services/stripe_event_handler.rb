class StripeEventHandler
  def self.customer_subscription_updated event
    user = Subscription.find_by!(stripe_customer_token: event.data.object.customer).user
    if event.data.previous_attributes.try(:plan)
      old_plan = event.data.previous_attributes.plan.id
      new_plan = event.data.object.plan.id
      AccountMailer.subscription_updated(user, old_plan, new_plan).deliver_later
    end
  end

  def self.trial_will_end event
    # send warning email
    user = Subscription.find_by!(stripe_customer_token: event.data.object.customer).user
    unless user.subscription.trial_ends_at < Date.today && user.subscription.on_trial?
      AccountMailer.trial_will_end(user).deliver_later
    end
  end

  def self.payment_failed event
    user = Subscription.find_by!(stripe_customer_token: event.data.object.customer).user
    unless event.data.object.lines.data[0].plan.id == "Free Trial"
      invoice = event.data.object
      AccountMailer.payment_failed(user, invoice).deliver_later
    end
  end

  def self.payment_succeeded event
    # figure out if this is an ended free trial
    subscription = Subscription.find_by!(stripe_customer_token: event.data.object.customer)
    user = subscription.user
    if event.data.object.lines.data[0].plan.id == "Free Trial"
      if subscription.trial_ends_at < Date.today
        AccountMailer.trial_ended(user).deliver_later
      end
    else
      invoice = {}
      invoice[:currency] = event.data.object.currency
      invoice[:amount] = event.data.object.lines.data[0].amount
      invoice[:amount_due] = event.data.object.amount_due
      invoice[:id] = event.data.object.id
      invoice[:plan_id] = event.data.object.lines.data[0].plan.id
      if event.data.object.discount.try(:coupon)
        invoice[:coupon] = Hash(event.data.object.discount.coupon)
      end
      AccountMailer.invoice(user, invoice).deliver_later
    end
  end
end
