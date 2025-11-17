## 1. Teorema CAP
Teorema CAP  atau Brewer's Theorem menyatakan bahwa dalam sistem komputer terdistribusi, Anda **hanya dapat memiliki 2 dari 3** jaminan berikut secara bersamaan:

### Tiga hal yang utama dalam CAP:
1.  **C - Consistency (Konsistensi):**
    * Setiap pembacaan (*read*) akan menerima data tulisan (*write*) yang paling baru atau pesan error.
    * *Intinya: Semua user melihat data yang sama persis pada waktu yang sama.*
2.  **A - Availability (Ketersediaan):**
    * Setiap permintaan (*request*) mendapat respons (sukses/gagal), tanpa jaminan datanya paling baru.
    * *Intinya: Sistem tidak boleh "down" atau menolak permintaan user.*
3.  **P - Partition Tolerance (Toleransi Partisi):**
    * Sistem terus beroperasi meskipun ada pesan yang hilang atau koneksi putus antar node (server).

### Aturan Main dari teorema CAP:
Karena dalam sistem terdistribusi jaringan bisa saja putus (**P** pasti terjadi), maka pilihannya hanya dua:
* **CP (Consistency + Partition Tolerance):** Jika jaringan putus, sistem **menolak request** demi menjaga data tetap akurat.
* **AP (Availability + Partition Tolerance):** Jika jaringan putus, sistem **tetap menjawab** (mungkin dengan data lama) demi menjaga layanan tetap jalan.

---

## 2. Teorema BASE 
BASE adalah **strategi desain** untuk sistem yang memilih jalur **AP** (Availability > Consistency). Ini adalah kebalikan dari konsep **CAP** pada database SQL tradisional.

* **BA - Basically Available:** Sistem dijamin akan merespons, tetapi mungkin tidak memberikan jawaban paling update.
* **S - Soft State:** Status sistem bisa berubah seiring waktu (belum sinkron) bahkan tanpa input baru.
* **E - Eventual Consistency:** Sistem akan menjadi konsisten **pada akhirnya**. Jika ditunggu beberapa saat, semua node akan memiliki data yang sama.

---

## 3. Keterkaitan Keduanya
Hubungannya sangat erat: **BASE adalah implementasi praktis dari sistem yang memprioritaskan Availability (AP) dalam Teorema CAP.**

| Kategori | Filosofi | Contoh Teknologi |
| :--- | :--- | :--- |
| **SQL (RDBMS)** | Cenderung **CAP** (Pilih Konsistensi/CP) | MySQL, PostgreSQL, Oracle |
| **NoSQL** | Cenderung **BASE** (Pilih Ketersediaan/AP) | Cassandra, DynamoDB, MongoDB |

---

## 4. Contoh Kasus yang sering saya gunakan adalah penggunaan ATM dan Media Sosial.

### Skenario A: Transfer Uang (Pendekatan CAP)
* **Contoh:** ATM Bank.
* **Kasus:** Saldo Rp1.000.000. Anda tarik tunai di Jakarta, istri Anda tarik tunai di Surabaya pada detik yang sama.
* **Logika:** Bank wajib memilih **Consistency**.
* **Hasil:** Bank tidak boleh membiarkan uang keluar ganda. Jika koneksi antar cabang putus, ATM akan menampilkan *"Maaf, layanan tidak tersedia"* (Mengorbankan Availability).

### Skenario B: Jumlah "Likes" (Pendekatan BASE)
* **Contoh:** Postingan viral di Instagram/Twitter.
* **Kasus:** 5.000 orang menekan tombol "Like" dalam 1 detik.
* **Logika:** Media sosial memilih **Availability**.
* **Hasil (Penerapan BASE):**
    1.  *Basically Available:* Tombol like langsung berubah warna (respons cepat).
    2.  *Soft State:* Di HP Anda tertulis "1.500 likes", di HP teman tertulis "1.520 likes" (Data berbeda sementara).
    3.  *Eventual Consistency:* Setelah beberapa detik, server melakukan sinkronisasi dan semua orang akhirnya melihat angka "5.000 likes".
