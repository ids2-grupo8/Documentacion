workspace "Bazaar" "Arquitectura del marketplace Bazaar (modelo C4)" {

    model {
        !impliedRelationships true

        comprador = person "Comprador / Vendedor" "La misma cuenta compra y vende."
        visitante = person "Visitante" "Explora el catálogo sin autenticarse."
        admin = person "Administrador" "Modera y consulta métricas."

        mercadopago = softwareSystem "MercadoPago" "Gateway de pagos (mock)." "External"
        supabase = softwareSystem "Supabase" "OAuth Google + PostgreSQL." "External"
        google = softwareSystem "Google" "Identidad federada (OAuth 2.0)." "External"
        cloudinary = softwareSystem "Cloudinary" "CDN de imágenes." "External"
        push = softwareSystem "Servicios de Push" "Expo Push y Web Push." "External"

        bazaar = softwareSystem "Bazaar" "Marketplace: usuarios, catálogo, checkout, órdenes y notificaciones." {

            mobile = container "Mobile App" "App de compra y venta para usuarios finales." "React Native / Expo"
            backoffice = container "Backoffice" "Panel de administración." "React + Vite"
            gateway = container "API Gateway" "Punto de entrada único: enrutamiento, TLS, rate-limiting." "Kong 3.9"

            userSvc = container "User Service" "Registro, login, perfiles, admin de usuarios." "Python / FastAPI" {
                us_apiAuth = component "Auth API" "Registro, login email/PIN/biométrico, recupero, federado." "FastAPI Router" "API"
                us_apiUser = component "User API" "Perfil propio y público, edición." "FastAPI Router" "API"
                us_apiAdmin = component "Admin API" "Listar usuarios, bloquear/desbloquear." "FastAPI Router" "API"
                us_svcAuth = component "Auth Service" "Credenciales, tokens, sesiones, rate-limit." "Lógica" "Logic"
                us_svcUser = component "User Service" "Datos de perfil y reglas de visibilidad." "Lógica" "Logic"
                us_svcAdmin = component "Admin Service" "Moderación de cuentas." "Lógica" "Logic"
                us_repos = component "Repositories" "Acceso a datos." "SQLAlchemy" "Adapter"
                us_prodClient = component "Product Client" "Publicaciones del usuario para el perfil." "Cliente HTTP" "Adapter"
                us_orderClient = component "Order Client" "Datos de órdenes para reputación." "Cliente HTTP" "Adapter"
            }
            userDb = container "User DB" "Usuarios, credenciales, sesiones, dispositivos." "PostgreSQL" "Database"

            productSvc = container "Product Service" "Catálogo, búsqueda, stock, moderación." "Python / FastAPI" {
                pr_apiProducts = component "Products API" "Listado, búsqueda, detalle, publicación, wishlist." "FastAPI Router" "API"
                pr_apiAdmin = component "Admin API" "Moderación: habilitar/deshabilitar productos." "FastAPI Router" "API"
                pr_svcProduct = component "Product Service" "Reglas de catálogo, stock, visibilidad y moderación." "Lógica" "Logic"
                pr_repo = component "Product Repository" "Persistencia en MongoDB." "Motor / PyMongo" "Adapter"
                pr_sellerClient = component "Seller Client" "Valida que el vendedor exista en user-service." "Cliente HTTP" "Adapter"
                pr_cloudinaryC = component "Image Uploader" "Sube y administra imágenes." "Cliente Cloudinary" "Adapter"
                pr_stockPub = component "Stock Publisher" "Publica stock.updated." "aio-pika" "Adapter"
                pr_stockCons = component "Stock Consumer" "Consume payment.* y ajusta stock." "aio-pika" "Adapter"
            }
            productDb = container "Product DB" "Productos, categorías, imágenes, wishlist." "MongoDB" "Database"

            checkoutSvc = container "Checkout Service" "Carrito, checkout, órdenes, pagos, cupones, reviews." "Python / FastAPI" {
                co_apiCart = component "Cart API" "Agregar/quitar items, ver carrito." "FastAPI Router" "API"
                co_apiCheckout = component "Checkout API" "Confirma compra e inicia pago." "FastAPI Router" "API"
                co_apiOrder = component "Order API" "Estado, seguimiento e historial de órdenes." "FastAPI Router" "API"
                co_apiCoupon = component "Coupon API" "Crear/gestionar/aplicar cupones." "FastAPI Router" "API"
                co_apiReview = component "Review API" "Calificar producto y vendedor." "FastAPI Router" "API"
                co_apiAdmin = component "Admin Orders API" "Listado/búsqueda de órdenes (solo lectura)." "FastAPI Router" "API"
                co_apiMetrics = component "Metrics API" "Métricas del sistema y por categoría." "FastAPI Router" "API"
                co_svcCheckout = component "Checkout Service" "Transacción, idempotencia, concurrencia de stock." "Lógica" "Logic"
                co_svcCart = component "Cart Service" "Gestión del carrito y validación de stock." "Lógica" "Logic"
                co_svcOrder = component "Order Service" "Máquina de estados de la orden." "Lógica" "Logic"
                co_svcCoupon = component "Coupon Service" "Validación y aplicación de descuentos." "Lógica" "Logic"
                co_svcReview = component "Review Service" "Reglas de calificación post-entrega." "Lógica" "Logic"
                co_svcMetrics = component "Metrics Service" "Agregaciones y exportación." "Lógica" "Logic"
                co_repos = component "Repositories" "Acceso a datos (carritos, órdenes, cupones, reviews)." "SQLAlchemy" "Adapter"
                co_mpClient = component "MercadoPago Client" "Integración de pagos (real o mock)." "Cliente HTTP" "Adapter"
                co_prodClient = component "Product Client" "Consulta /products/batch y stock." "Cliente HTTP" "Adapter"
                co_userClient = component "User Client" "Consulta usuarios y direcciones." "Cliente HTTP" "Adapter"
                co_resilience = component "Resilience" "Retry / Circuit Breaker." "Tolerancia a fallos" "Adapter"
                co_publisher = component "Event Publisher" "Publica payment.* y order.status_changed." "aio-pika" "Adapter"
                co_expiry = component "Order Expiry Task" "Expira órdenes pendientes de pago." "Background task" "Adapter"
            }
            checkoutDb = container "Checkout DB" "Carritos, órdenes, transiciones, cupones, reviews." "PostgreSQL" "Database"

            notifSvc = container "Notification Service" "Consume eventos y entrega notificaciones." "Go" {
                no_handler = component "HTTP Handlers" "Registro de suscripciones push y consulta." "Go / net/http" "API"
                no_orderCons = component "Order Consumer" "Consume order.status_changed." "Go / amqp" "API"
                no_stockCons = component "Stock Consumer" "Consume stock.updated." "Go / amqp" "API"
                no_svc = component "Notification Service" "Decide destinatario y construye el mensaje." "Lógica" "Logic"
                no_repo = component "Repository" "Suscripciones y notificaciones emitidas." "mongo-driver" "Adapter"
                no_userC = component "User Client" "Resuelve email del comprador/vendedor." "Cliente HTTP" "Adapter"
                no_checkoutC = component "Checkout Client" "Enriquece datos de la orden." "Cliente HTTP" "Adapter"
                no_expo = component "Expo Push" "Notificaciones a la app móvil." "Cliente HTTP" "Adapter"
                no_webpush = component "Web Push" "Notificaciones al navegador." "VAPID" "Adapter"
            }
            notifDb = container "Notification DB" "Suscripciones push y notificaciones emitidas." "MongoDB" "Database"

            rabbit = container "Message Broker" "Exchanges topic con DLX: payments, orders, stock." "RabbitMQ 3.13" "Queue"
        }

        # ---- Relaciones nivel contenedor ----
        comprador -> mobile "Usa" "HTTPS"
        visitante -> mobile "Explora y busca" "HTTPS"
        admin -> backoffice "Usa" "HTTPS"

        mobile -> gateway "Llama API REST" "HTTPS/JSON"
        backoffice -> gateway "Llama API REST" "HTTPS/JSON"

        gateway -> userSvc "Enruta /users" "HTTP"
        gateway -> productSvc "Enruta /products" "HTTP"
        gateway -> checkoutSvc "Enruta /checkout, /orders, /cart" "HTTP"
        gateway -> notifSvc "Enruta /notifications" "HTTP"

        checkoutSvc -> productSvc "Consulta productos y stock" "REST"
        checkoutSvc -> userSvc "Consulta usuarios/direcciones" "REST"
        productSvc -> userSvc "Valida vendedor" "REST"
        notifSvc -> userSvc "Resuelve emails" "REST"
        notifSvc -> productSvc "Enriquece producto" "REST"
        notifSvc -> checkoutSvc "Enriquece orden" "REST"

        # Integraciones externas a nivel contenedor (declaradas antes que los
        # componentes para que las relaciones implícitas no se dupliquen)
        checkoutSvc -> mercadopago "Procesa pagos" "HTTPS"
        checkoutSvc -> supabase "Persiste órdenes (prod)" "PostgreSQL"
        userSvc -> supabase "OAuth Google federado" "HTTPS"
        supabase -> google "Delega autenticación" "OAuth 2.0"
        productSvc -> cloudinary "Sube imágenes" "HTTPS"
        notifSvc -> push "Entrega notificaciones" "HTTPS"

        # ---- Relaciones nivel componente ----
        # User Service
        us_apiAuth -> us_svcAuth
        us_apiUser -> us_svcUser
        us_apiAdmin -> us_svcAdmin
        us_svcAuth -> us_repos
        us_svcUser -> us_repos
        us_svcAdmin -> us_repos
        us_svcAuth -> supabase "Verifica OAuth" "HTTPS"
        us_svcUser -> us_prodClient "Publicaciones del perfil"
        us_svcUser -> us_orderClient "Reputación / historial"
        us_repos -> userDb "Lee/escribe" "SQL"
        us_prodClient -> productSvc "REST"
        us_orderClient -> checkoutSvc "REST"

        # Product Service
        pr_apiProducts -> pr_svcProduct
        pr_apiAdmin -> pr_svcProduct
        pr_svcProduct -> pr_repo
        pr_svcProduct -> pr_sellerClient "Valida vendedor"
        pr_svcProduct -> pr_cloudinaryC "Sube imágenes"
        pr_svcProduct -> pr_stockPub "Notifica cambios de stock"
        pr_stockCons -> pr_repo "Descuenta/restaura stock"
        pr_repo -> productDb "Lee/escribe" "Mongo"
        pr_sellerClient -> userSvc "REST"
        pr_cloudinaryC -> cloudinary "HTTPS"
        pr_stockPub -> rabbit "Publica stock.updated" "AMQP"
        rabbit -> pr_stockCons "Consume payment.*" "AMQP"

        # Checkout Service
        co_apiCart -> co_svcCart
        co_apiCheckout -> co_svcCheckout
        co_apiOrder -> co_svcOrder
        co_apiCoupon -> co_svcCoupon
        co_apiReview -> co_svcReview
        co_apiMetrics -> co_svcMetrics
        co_apiAdmin -> co_svcOrder
        co_svcCheckout -> co_svcCart "Lee carrito"
        co_svcCheckout -> co_svcCoupon "Aplica cupón"
        co_svcCheckout -> co_mpClient "Cobra"
        co_svcCheckout -> co_prodClient "Verifica stock"
        co_svcCheckout -> co_publisher "Publica payment.*"
        co_svcOrder -> co_publisher "Publica order.status_changed"
        co_svcCart -> co_repos
        co_svcOrder -> co_repos
        co_svcCoupon -> co_repos
        co_svcReview -> co_repos
        co_svcMetrics -> co_repos
        co_expiry -> co_repos "Expira órdenes"
        co_prodClient -> co_resilience
        co_userClient -> co_resilience
        co_repos -> checkoutDb "Lee/escribe" "SQL"
        co_mpClient -> mercadopago "Procesa pagos" "HTTPS"
        co_prodClient -> productSvc "REST"
        co_userClient -> userSvc "REST"
        co_publisher -> rabbit "Publica payment.* / order.status_changed" "AMQP"

        # Notification Service
        rabbit -> no_orderCons "order.status_changed" "AMQP"
        rabbit -> no_stockCons "stock.updated" "AMQP"
        no_orderCons -> no_svc
        no_stockCons -> no_svc
        no_handler -> no_repo "Guarda suscripción"
        no_svc -> no_repo "Persiste notificación"
        no_svc -> no_userC "Resuelve email"
        no_svc -> no_checkoutC "Enriquece orden"
        no_svc -> no_expo "Envía"
        no_svc -> no_webpush "Envía"
        no_repo -> notifDb "Lee/escribe" "Mongo"
        no_userC -> userSvc "REST"
        no_checkoutC -> checkoutSvc "REST"
        no_expo -> push "HTTPS"
        no_webpush -> push "HTTPS"
    }

    views {
        systemContext bazaar "Contexto" {
            include *
            autoLayout
        }

        container bazaar "Contenedores" {
            include *
            autoLayout
        }

        component checkoutSvc "Componentes-Checkout" {
            include *
            autoLayout
        }

        component productSvc "Componentes-Product" {
            include *
            autoLayout
        }

        component userSvc "Componentes-User" {
            include *
            autoLayout
        }

        component notifSvc "Componentes-Notification" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #0f766e
                color #ffffff
            }
            element "Software System" {
                background #7c3aed
                color #ffffff
            }
            element "External" {
                background #475569
                color #ffffff
            }
            element "Container" {
                background #2563eb
                color #ffffff
            }
            element "Database" {
                shape Cylinder
                background #6d28d9
                color #ffffff
            }
            element "Queue" {
                shape Pipe
                background #c2410c
                color #ffffff
            }
            element "Component" {
                background #2563eb
                color #ffffff
            }
            element "API" {
                background #1d4ed8
                color #ffffff
            }
            element "Logic" {
                background #0e7490
                color #ffffff
            }
            element "Adapter" {
                background #0f766e
                color #ffffff
            }
        }
    }
}
