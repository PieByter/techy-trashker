import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { createTestContext, type TestContext } from './helpers/app';

let ctx: TestContext;

beforeAll(async () => {
  ctx = await createTestContext();
});

afterAll(async () => {
  await ctx.app.close();
});

describe('content endpoints', () => {
  it('lists news with pagination and filters', async () => {
    const page = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/news?page=1&limit=2',
    });

    expect(page.statusCode).toBe(200);
    const body = page.json();
    expect(body.data).toHaveLength(2);
    expect(body.meta).toMatchObject({
      page: 1,
      limit: 2,
      total: 3,
      totalPages: 2,
      hasNext: true,
      hasPrev: false,
    });

    const filtered = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/news?category=Tips&q=milah',
    });

    expect(filtered.statusCode).toBe(200);
    expect(filtered.json().data).toHaveLength(1);
    expect(filtered.json().data[0].category).toBe('Tips');
  });

  it('returns news detail with content', async () => {
    const list = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/news?limit=1',
    });
    const id = list.json().data[0].id;

    const detail = await ctx.app.inject({
      method: 'GET',
      url: `/api/v1/news/${id}`,
    });

    expect(detail.statusCode).toBe(200);
    expect(detail.json().content).toBeTruthy();
    expect(detail.json().imageUrl).toContain('/static/news/');
  });

  it('returns 404 for unknown news', async () => {
    const response = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/news/00000000-0000-4000-8000-000000000099',
    });

    expect(response.statusCode).toBe(404);
    expect(response.json().error.code).toBe('NEWS_NOT_FOUND');
  });

  it('sorts waste banks by distance and filters open banks', async () => {
    const response = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/waste-banks',
    });

    expect(response.statusCode).toBe(200);
    const data = response.json().data;
    expect(data).toHaveLength(4);
    expect(data[0].name).toBe('Bank Sampah Berseri');
    expect(data[0].distanceKm).toBeLessThan(data[1].distanceKm);

    const open = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/waste-banks?openOnly=true',
    });

    expect(open.statusCode).toBe(200);
    expect(open.json().data).toHaveLength(3);
    expect(
      open.json().data.every((bank: { isOpen: boolean }) => bank.isOpen),
    ).toBe(true);
  });

  it('searches waste banks and returns detail', async () => {
    const search = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/waste-banks?q=eco',
    });

    expect(search.statusCode).toBe(200);
    expect(search.json().data).toHaveLength(1);

    const id = search.json().data[0].id;
    const detail = await ctx.app.inject({
      method: 'GET',
      url: `/api/v1/waste-banks/${id}?lat=3.5952&lng=98.6722`,
    });

    expect(detail.statusCode).toBe(200);
    expect(detail.json()).toMatchObject({
      id,
      name: 'Bank Sampah Eco Center',
      isOpen: false,
    });
    expect(detail.json().distanceKm).toBeGreaterThan(0);
  });

  it('validates location query pairs', async () => {
    const response = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/waste-banks?lat=3.5',
    });

    expect(response.statusCode).toBe(400);
    expect(response.json().error.code).toBe('VALIDATION_ERROR');
  });

  it('serves static images and API metadata', async () => {
    const image = await ctx.app.inject({
      method: 'GET',
      url: '/static/news/news-1.jpg',
    });
    expect(image.statusCode).toBe(200);
    expect(image.headers['content-type']).toContain('image/jpeg');

    const root = await ctx.app.inject({ method: 'GET', url: '/api/v1' });
    expect(root.statusCode).toBe(200);
    expect(root.json().docs).toBe('/docs');
  });

  it('publishes OpenAPI documentation', async () => {
    const response = await ctx.app.inject({
      method: 'GET',
      url: '/docs/json',
    });

    expect(response.statusCode).toBe(200);
    const spec = response.json();
    expect(spec.openapi).toBe('3.0.3');
    expect(spec.paths['/api/v1/me']).toBeTruthy();
    expect(spec.paths['/api/v1/officer/deposits']).toBeTruthy();
    expect(spec.components.securitySchemes.bearerAuth).toMatchObject({
      type: 'http',
      scheme: 'bearer',
    });
  });

  it('returns the standard error envelope for unknown routes', async () => {
    const response = await ctx.app.inject({
      method: 'GET',
      url: '/api/v1/tidak-ada',
    });

    expect(response.statusCode).toBe(404);
    expect(response.json().error.code).toBe('NOT_FOUND');
  });
});
