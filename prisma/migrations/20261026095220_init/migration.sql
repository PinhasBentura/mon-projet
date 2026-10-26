-- CreateTable
CREATE TABLE "clients" (
    "id" SERIAL NOT NULL,
    "nom" VARCHAR(100) NOT NULL,
    "ville" VARCHAR(100),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "clients_pkey" PRIMARY KEY ("id")
);
