import { prisma } from '@/lib/prisma';

export const dynamic = 'force-dynamic';

export default async function Home() {
  const clients = await prisma.client.findMany({ orderBy: { id: 'asc' } });

  return (
    <main>
      <h1>TEST PR</h1>
      <h1>Clients</h1>
      <p style={{ color: '#57606a' }}>Données lues avec Prisma dans PostgreSQL (conteneur « db »)</p>
      <table style={{ borderCollapse: 'collapse', minWidth: 420 }}>
        <thead>
          <tr>
            {['ID', 'Nom', 'Ville', 'Téléphone'].map((h) => (
              <th key={h} style={{ textAlign: 'left', padding: '8px 12px', background: '#24292f', color: '#fff' }}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {clients.map((c) => (
            <tr key={c.id}>
              {[c.id, c.nom, c.ville, c.telephone].map((v, i) => (
                <td key={i} style={{ padding: '8px 12px', borderBottom: '1px solid #d0d7de' }}>{v}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </main>
  );
}
