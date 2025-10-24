ActiveAdmin.register_page "Dashboard" do
  content title: "Admin Dashboard" do

    # Date filter form
    form action: admin_dashboard_path, method: :get do |f|
      div do
        label "Start Date"
        input type: :date, name: "start_date", value: params[:start_date]
      end
      div do
        label "End Date"
        input type: :date, name: "end_date", value: params[:end_date]
      end
      div do
        input type: :submit, value: "Filter", class: "btn btn-primary"
      end
    end

    # Apply date filter
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 1.month.ago.to_date
    end_date   = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today

    columns do
      column do
        panel "Total Users" do
          h1 User.count
        end
      end

      column do
        panel "Total Products" do
          h1 Product.count
        end
      end
    end

    columns do
      column do
        panel "Total Orders & Sales" do
          orders = Order.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
          line_chart orders.group_by_day(:created_at).sum(:total),
                     xtitle: "Date", ytitle: "Total Sales (KES)"
        end
      end

      column do
        panel "Orders Status Distribution" do
          orders = Order.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
          pie_chart orders.group(:status).count
        end
      end
    end

    columns do
      column do
        panel "Orders Per Seller" do
          # ✅ FIX: use active_role instead of role
          sellers = User.where(active_role: "seller")
          bar_chart sellers.map { |s|
            [s.email, s.orders_as_seller.where(created_at: start_date.beginning_of_day..end_date.end_of_day).sum(:total)]
          }.to_h
        end
      end

      column do
        panel "Orders Per Product" do
          products = Product.all
          bar_chart products.map { |p|
            [p.title, p.orders.where(created_at: start_date.beginning_of_day..end_date.end_of_day).sum(:total)]
          }.to_h
        end
      end
    end

    columns do
      column do
        panel "Total Payments Collected" do
          payments = Payment.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
          line_chart payments.group_by_day(:created_at).sum(:amount),
                     xtitle: "Date", ytitle: "Total Payments (KES)"
        end
      end
    end

    columns do
      column do
        panel "Recent Orders" do
          table_for Order.order(created_at: :desc).limit(5) do
            column :id
            column :buyer
            column :seller
            column :status
            column :total
            column :created_at
          end
        end
      end
    end

    columns do
      column do
        panel "Unread Notifications" do
          table_for Notification.where(read: false).limit(10) do
            column :user
            column :message
            column :created_at
          end
        end
      end

      column do
        panel "Recent Shipment Changes" do
          table_for ShipmentStatusLog.order(changed_at: :desc).limit(10) do
            column :shipment
            column :status
            column :changed_by
            column :changed_at
          end
        end
      end
    end
  end
end
