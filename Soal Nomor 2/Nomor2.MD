# GraphQL dan Komunikasi Antar Proses (IPC) pada Sistem Terdistribusi

## 1. Penjelasan Konsep
Dalam sistem terdistribusi (seperti *Microservices*), aplikasi dipecah menjadi bagian-bagian kecil (proses) yang berjalan secara terpisah. GraphQL berperan sebagai **mekanisme komunikasi sinkron** di Lapisan Aplikasi (*Application Layer*).

Tiga keterkaitan utamanya adalah:

1.  **Sebagai Kontrak Data (Strongly Typed Contract)**
    Dalam IPC, Client dan Server harus sepakat mengenai format data. GraphQL menyediakan *Schema* yang ketat. Ini memastikan pesan yang dikirim antar proses valid, mengurangi risiko *parsing error* saat komunikasi.

2.  **Efisiensi Bandwidth (Data Fetching)**
    Tantangan utama IPC adalah *latency* jaringan. GraphQL meminimalisir ini dengan membolehkan Client meminta *hanya* data yang dibutuhkan, mencegah pengiriman data sampah (*Over-fetching*) yang membebani jalur komunikasi.

3.  **Abstraksi Kompleksitas (The Aggregator)**
    Dalam sistem terdistribusi, data mungkin tersebar di berbagai layanan (*Service A, Service B, Database Legacy*). GraphQL bertindak sebagai satu pintu gerbang (*Gateway*). Satu pesan IPC dari Client ke GraphQL dapat memicu serangkaian komunikasi IPC internal di *backend*, lalu hasilnya digabung menjadi satu respon rapi.

---

## 2. Diagram Keterkaitan

```mermaid
graph TD
    %% Definisi Node dan Style
    subgraph Client_Layer [Layer 1: Client / Proses A]
        Client["Aplikasi Web/Mobile"]
    end

    subgraph Gateway_Layer [Layer 2: GraphQL Gateway / Proses B]
        GQL["GraphQL Server"]
        Resolver["Resolver Logic"]
    end

    subgraph Service_Layer [Layer 3: Backend Services / Proses C, D, E]
        SvcA["User Service<br>(gRPC)"]
        SvcB["Product Service<br>(REST)"]
        DB[("Database")]
    end

    %% Alur Komunikasi (IPC)
    Client -- "1. HTTP Request (JSON)" --> GQL
    GQL -- "2. Parse & Validasi" --> Resolver
    
    Resolver -- "3. Fetch (gRPC)" --> SvcA
    Resolver -- "4. Fetch (HTTP/REST)" --> SvcB
    Resolver -- "5. Query (TCP)" --> DB

    %% Alur Balikan
    SvcA & SvcB & DB -.-> Resolver
    Resolver -- "6. Agregasi Data" --> GQL
    GQL -- "7. HTTP Response (JSON)" --> Client

    %% Pewarnaan
    style GQL fill:#6E44FF,color:#fff,stroke:#fff
    style Resolver fill:#B19CD9,color:#000,stroke:#333
    style Client fill:#333,color:#fff,stroke:#fff

## Penjelasan diagram
1. Inisiasi (Proses 1 ke 2): Client mengirim pesan IPC (biasanya via HTTP) berisi Query GraphQL. Ini berisi daftar spesifik data yang diminta.
2. Validasi & Resolusi (Proses 2): Server GraphQL menerima pesan dan mengecek Schema (kontrak) untuk memastikan permintaan valid.
3. Distribusi Request (Proses 2 ke Backend): Di sinilah peran krusial GraphQL. Fungsi Resolver bertindak sebagai pengatur lalu lintas. Ia melakukan IPC internal ke berbagai sumber:
- Ke Microservice A (misal: data user).
- Ke Database langsung.
- Ke Microservice B (misal: data produk).
4. Agregasi & Respon: Data dari berbagai sumber dikumpulkan (aggregated), difilter agar sesuai permintaan Client, dan dikirim kembali sebagai satu paket JSON.
