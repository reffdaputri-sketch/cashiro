'use client';

import { useSearchParams } from 'next/navigation';

export default function UnauthorizedPage() {
  const searchParams = useSearchParams();
  const reason = searchParams.get('reason');

  let message = 'Lisensi Anda tidak valid atau telah kedaluwarsa.';
  
  if (reason === 'no_key') {
    message = 'Lisensi tidak ditemukan. Harap masukkan LICENSE_KEY di pengaturan server Anda.';
  } else if (reason === 'invalid_key') {
    message = 'Lisensi yang Anda gunakan tidak valid, telah diblokir, atau digunakan di domain yang salah.';
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100">
      <div className="bg-white p-8 rounded-lg shadow-md max-w-md w-full text-center">
        <div className="text-red-500 mb-4">
          <svg className="w-16 h-16 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
          </svg>
        </div>
        <h1 className="text-2xl font-bold text-gray-800 mb-2">Akses Ditolak</h1>
        <p className="text-gray-600 mb-6">{message}</p>
        <div className="p-4 bg-gray-50 rounded text-sm text-gray-500 mb-6">
          <p>Sistem mendeteksi adanya pelanggaran lisensi. Silakan hubungi tim developer KIOSLY untuk melakukan aktivasi atau perpanjangan lisensi Anda.</p>
        </div>
        <a 
          href="https://wa.me/628123456789" // Ganti dengan nomor WA Anda
          className="inline-block w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded transition duration-200"
        >
          Hubungi Developer
        </a>
      </div>
    </div>
  );
}
