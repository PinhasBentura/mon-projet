export const metadata = { title: 'Mon projet' };

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr">
      <body style={{ fontFamily: 'system-ui, sans-serif', margin: 40, color: '#1f2328' }}>{children}</body>
    </html>
  );
}
