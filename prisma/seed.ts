import 'dotenv/config';
import { prisma } from '../lib/prisma';

async function main() {
  await prisma.client.createMany({
    data: [
      { nom: 'Boulangerie Martin', ville: 'Lyon', telephone: '04 78 12 34 56' },
      { nom: 'Garage Dupont', ville: 'Lille', telephone: '03 20 98 76 54' },
      { nom: 'Pharmacie du Centre', ville: 'Nantes', telephone: '02 40 11 22 33' },
    ],
    skipDuplicates: true,
  });
}

main().finally(() => prisma.$disconnect());
