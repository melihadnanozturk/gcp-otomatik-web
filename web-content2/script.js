// script.js

// Sayfa tamamen yüklendiğinde çalışacak kod bloğu
document.addEventListener('DOMContentLoaded', function() {
    // Buton ve mesaj div'ini HTML'deki id'lerini kullanarak seçiyoruz
    const button = document.getElementById('checkWeatherBtn');
    const messageBox = document.getElementById('message');

    // Butona tıklanma olayı ekliyoruz
    button.addEventListener('click', function() {
        // Mesaj kutusuna istediğimiz metni ekliyoruz
        messageBox.textContent = "2.Sayfa mesaj";

        // Mesaj kutusunu görünür hale getirmek için 'visible' sınıfını ekliyoruz
        messageBox.classList.add('visible');

        // İsteğe bağlı: Butonu tekrar tıklanabilir yapmak için belirli bir süre sonra gizleyebilirsiniz
        // setTimeout(function() {
        //     messageBox.classList.remove('visible');
        //     messageBox.textContent = ''; // Mesajı temizle
        // }, 5000); // 5 saniye sonra kaybolsun (isteğe bağlı)
    });
});