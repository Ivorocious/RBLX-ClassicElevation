import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

MODULE = Path(__file__).resolve().parents[1] / 'tools/upload_roblox_model.py'
spec = importlib.util.spec_from_file_location('roblox_upload', MODULE)
uploader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(uploader)


class UploadTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.file = Path(self.directory.name) / 'tree.fbx'
        self.file.write_bytes(b'Kaydara FBX Binary test data')
        self.receipt = Path(self.directory.name) / 'receipt.json'
        self.identity, self.body, self.content_type = uploader.prepare(self.file, '86069177', 'Tree')

    def run_upload(self):
        return uploader.upload(self.identity, self.body, self.content_type, self.receipt, 'test-secret', 0)

    def test_multipart_contains_exact_file_and_creator(self):
        self.assertIn(self.file.read_bytes(), self.body)
        self.assertIn(b'"userId": "86069177"', self.body)
        self.assertIn(b'Content-Type: model/fbx', self.body)
        self.assertNotIn(b'test-secret', self.body)

    def test_completed_upload_does_not_submit_twice(self):
        with patch.object(uploader, 'api_request', side_effect=[
            {'path': 'operations/123'}, {'done': True, 'response': {'assetId': '456'}},
        ]) as request:
            self.assertEqual(self.run_upload()['assetId'], '456')
            self.assertEqual(self.run_upload()['assetId'], '456')
            self.assertEqual(request.call_count, 2)
        self.assertNotIn('test-secret', self.receipt.read_text())

    def test_uncertain_submission_is_not_repeated(self):
        with patch.object(uploader, 'api_request', side_effect=uploader.UploadError('Network failure')) as request:
            with self.assertRaises(uploader.UploadError):
                self.run_upload()
            with self.assertRaisesRegex(uploader.UploadError, 'unknown outcome'):
                self.run_upload()
            self.assertEqual(request.call_count, 1)

    def test_pending_operation_resumes_without_upload(self):
        self.receipt.write_text(json.dumps(dict(self.identity, state='pending', operation='operations/123')))
        with patch.object(uploader, 'api_request', return_value={'done': True, 'response': {'assetId': '456'}}) as request:
            self.assertEqual(self.run_upload()['assetId'], '456')
            self.assertEqual(request.call_args.args[:2], ('GET', 'operations/123'))

    def test_receipt_cannot_be_reused_for_changed_file(self):
        self.receipt.write_text(json.dumps(dict(self.identity, state='complete', assetId='456')))
        self.identity['sha256'] = 'changed'
        with patch.object(uploader, 'api_request') as request:
            with self.assertRaisesRegex(uploader.UploadError, 'different input'):
                self.run_upload()
            request.assert_not_called()

    def test_operation_path_cannot_send_credentials_elsewhere(self):
        with self.assertRaisesRegex(uploader.UploadError, 'Invalid operation path'):
            uploader.api_request('GET', 'https://example.com/steal', 'test-secret')
        self.assertIsNone(uploader.NoRedirect().redirect_request(None, None, 302, '', {}, 'https://example.com'))

    def test_processing_failure_is_not_success(self):
        with patch.object(uploader, 'api_request', side_effect=[
            {'path': 'operations/123'}, {'done': True, 'error': {'code': 3}},
        ]):
            with self.assertRaisesRegex(uploader.UploadError, 'processing failure'):
                self.run_upload()
        self.assertEqual(json.loads(self.receipt.read_text())['state'], 'failed')


if __name__ == '__main__':
    unittest.main()
