```typescript
import { useEffect } from 'react';
import { useRouter } from 'next/router';
import { Layout } from '@/components/layout/Layout';
import { ServiceList } from '@/components/admin/services/ServiceList';
import { useServices } from '@/hooks/useServices';

export default function ServicesPage() {
  const router = useRouter();
  const { 
    services, 
    isLoading, 
    updatingId,
    loadServices, 
    toggleVisibility,
    handleDelete 
  } = useServices();

  useEffect(() => {
    loadServices();
  }, [loadServices]);

  if (isLoading) {
    return (
      <Layout>
        <div className="flex justify-center items-center min-h-screen">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="min-h-screen bg-gray-50">
        <div className="bg-white shadow">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
            <div className="flex justify-between items-center">
              <h1 className="text-2xl font-bold text-gray-900">Manage Services</h1>
              <button
                onClick={() => router.push('/admin/dashboard')}
                className="text-gray-600 hover:text-gray-900"
              >
                Back to Dashboard
              </button>
            </div>
          </div>
        </div>

        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="flex justify-end mb-8">
            <button
              onClick={() => router.push('/admin/dashboard/services/new')}
              className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700"
            >
              Add Service
            </button>
          </div>

          <div className="bg-white rounded-lg shadow">
            <ServiceList 
              services={services}
              updatingId={updatingId}
              onToggleVisibility={toggleVisibility}
              onDelete={handleDelete}
            />
          </div>
        </div>
      </div>
    </Layout>
  );
}
```